import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.2
import QtQuick.XmlListModel 2.12
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

LauncherPage {
    id: conversationPage
    anchors.fill: parent

    property var headline
    property var textInputField
    property string textInput
    property string attachmentUrl: imagePicker.imageUrl
    property real widthFactor: 0.9
    property real innerSmallSpacing: 6.0
    property real navBarHeight: 0
    property int threadAge: 84000 * 14 // two weeks in milli seconds
    property int operationCount: 0 // number of background operations
    property int currentConversationMode: 0
    property var currentId: 0
    property var currentConversationModel: personContentModel
    property var messages: new Array
    property var calls: new Array
    property var phoneNumber

    property string m_ID:        "id"      // the id of the message or content
    property string m_TEXT:      "text"    // large main text, regular
    property string m_STEXT:     "stext"   // small text beyond the main text, grey
    property string m_IMAGE:     "image"   // preview image
    property string m_PART_IDs:  "partIds" // the ids of mms message parts
    property bool   m_IS_SENT:   false     // true if the content was sent by user
    property string m_KIND:      "kind"    // kind of content like sms or mms
    property string m_DATE:      "date"    // date in milliseconds of the item
    property string m_ERROR:     "error"   // error message under message

    Connections {
        target: Qt.inputMethod

        onKeyboardRectangleChanged: {
            console.debug("Conversation | Keyboard rectangle: " + Qt.inputMethod.keyboardRectangle)

            var delta = Qt.inputMethod.keyboardRectangle.height === 0
                    ? 0 : mainWindow.visibility === 5 ?
                          conversationPage.navBarHeight + Screen.desktopAvailableHeight / 16
                        : conversationPage.navBarHeight + Screen.desktopAvailableHeight / 62 // estimated navigation bar height

            listView.height = Screen.desktopAvailableHeight - Qt.inputMethod.keyboardRectangle.height / Screen.devicePixelRatio - delta
            listView.positionViewAtEnd()
        }
    }

    Component.onCompleted: {
        AN.SystemDispatcher.dispatch("volla.launcher.navBarAction", {})
    }

    onTextInputChanged: {
        console.log("Conversation | text input changed")
        currentConversationModel.update(textInput)
    }

    function updateConversationPage (mode, id, name) {
        console.log("Conversation | Update conversation mode: " + mode + " with id " + id)

        if (mode !== currentConversationMode || currentId !== id) {
            currentConversationMode = mode
            currentConversationModel.clear()
            currentConversationModel.modelArr = new Array

            switch (mode) {
                case mainView.conversationMode.Person:
                    headline.text = name
                    currentId = id
                    currentConversationModel = personContentModel

                    // Get contact by Id
                    var numbers = new Array
                    for (var i = 0; i < mainView.getContacts().length; i++) {
                        var contact = mainView.getContacts()[i]
                        if (contact["id"] === currentId) {
                            console.log("Conversation | Found contact " + contact["name"])
                            if (contact["phone.mobile"] !== undefined) {
                                numbers.push(contact["phone.mobile"])
                                phoneNumber = contact["phone.mobile"]
                            }
                            if (contact["phone.work"] !== undefined) numbers.push(contact["phone.work"])
                            if (contact["phone.home"] !== undefined) numbers.push(contact["phone.home"])
                            if (contact["phone.other"] !== undefined) numbers.push(contact["phone.other"])
                            break
                        }
                    }
                    operationCount = 3
                    mainView.updateSpinner(true)
                    loadConversation({"personId": id, "numbers": numbers, "threadAge": threadAge, "person": name})
                    loadCalls({"match": name, "age": threadAge})
                    break;
                case mainView.conversationMode.Thread:
                    headline.text = name
                    currentId = id
                    currentConversationModel = threadContentModel
                    operationCount = 2
                    mainView.updateSpinner(true)
                    loadConversation({"threadId": id, "threadAge": threadAge})
                    break;
                default:
                    console.log("Conversation | Unknown conversation mode")
                    break;
            }
        }
   }

    function updateListModel() {
        console.log("Conversation | Operation count is " + operationCount)
        operationCount = operationCount - 1
        if (operationCount < 1) {
            mainView.updateSpinner(false)
            conversationPage.currentConversationModel.loadData()
            conversationPage.currentConversationModel.update(conversationPage.textInput)
        }
    }

    function updateImage(messageId, image) {
        console.log("Conversation | Update image of message " + messageId)
        for (var i = 0; i < currentConversationModel.modelArr.length; i++) {
            var aMessage = currentConversationModel.modelArr[i]
            if (aMessage.m_ID === messageId) {
                console.log("Conversation | Message matched")
                aMessage.m_IMAGE = "data:image/png;base64," + image
                currentConversationModel.modelArr[i] = aMessage
                break
            }
        }
        for (i = 0; i < currentConversationModel.count; i++) {
            var elem = currentConversationModel.get(i)
            if (elem.m_ID === messageId) {
                console.log("Conversation | List element matched")
                elem.m_IMAGE = "data:image/png;base64," + image
                currentConversationModel.set(i, elem)
                break
            }
        }
        listView.positionViewAtEnd()
    }

    function sortListModel() {
        var n;
        var i;
        for (n = 0; n < currentConversationModel.count; n++) {
            for (i=n+1; i < currentConversationModel.count; i++) {
                if (currentConversationModel.get(n).m_DATE > currentConversationModel.get(i).m_DATE) {
                    currentConversationModel.move(i, n, 1);
                    n = 0;
                }
            }
        }

        listView.positionViewAtEnd()
    }

    function loadConversation(filter) {
        console.log("Conversation | Will load messages: " + filter["threadId"])
        messages = new Array

        if (currentConversationMode === mainView.conversationMode.Person) {
            AN.SystemDispatcher.dispatch("volla.launcher.signalMessagesAction", filter)
            AN.SystemDispatcher.dispatch("volla.launcher.conversationAction", filter)
        } else {
            AN.SystemDispatcher.dispatch("volla.launcher.signalMessagesAction", filter)
            AN.SystemDispatcher.dispatch("volla.launcher.conversationAction", filter)
        }
    }

    function loadCalls(filter) {
        console.log("Conversation | Will load calls")
        calls = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.callConversationAction", filter)
    }

    function lastMessageIsFromSignal() {
        var lastMessage = conversationPage.currentConversationModel.get(conversationPage.currentConversationModel.count - 1)
        return lastMessage.m_STEXT.includes("Signal")
    }

    ListView {
        id: listView
        clip: true
        anchors.top: parent.top
        width: parent.width
        height: parent.height
        headerPositioning: mainView.backgroundOpacity === 1.0 ? ListView.PullBackHeader : ListView.InlineHeader
        footerPositioning: ListView.OverlayFooter  // mainView.backgroundOpacity === 1.0 ? ListView.OverlayFooter : ListView.InlineFooter

        header: Column {
            id: header
            width: parent.width
            z: 2

            property var gradientColer: Universal.background

            Label {
                id: headerLabel
                width: header.width - 2 * mainView.innerSpacing
                topPadding: mainView.innerSpacing * 2
                x: mainView.innerSpacing
                text: qsTr("Conversation")
                clip: mainView.backgroundOpacity === 1.0 ? true : false
                elide: mainView.backgroundOpacity === 1.0 ? Text.ElideNone : Text.ElideRight
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
                background: Rectangle {
                    color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                    border.color: "transparent"
                }
                Binding {
                    target: conversationPage
                    property: "headline"
                    value: headerLabel
                }
                LinearGradient {
                    id: headerLabelTruncator
                    height: headerLabel.height
                    width: headerLabel.width
                    z : headerLabel.z + 1
                    start: Qt.point(headerLabel.width - 2 * mainView.innerSpacing,0)
                    end: Qt.point(headerLabel.width,0)
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: "#00000000"
                        }
                        GradientStop {
                            position: 1.0
                            color: header.gradientColer
                        }
                    }
                    visible: mainView.backgroundOpacity === 1.0
                }
            }
            TextField {
                id: textField
                padding: mainView.innerSpacing
                x: mainView.innerSpacing
                width: parent.width -mainView.innerSpacing * 2
                placeholderText: qsTr("Filter messages ...")
                color: mainView.fontColor
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.largeFontSize
                leftPadding: 0.0
                rightPadding: 0.0
                background: Rectangle {
                    color: mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
                    border.color: "transparent"
                }
                Binding {
                    target: conversationPage
                    property: "textInput"
                    value: textField.displayText.toLowerCase()
                }
                Binding {
                    target: conversationPage
                    property: "textInputField"
                    value: textField
                }
                Button {
                    id: deleteButton
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: mainView.largeFontSize * 2
                    flat: true
                    topPadding: 0.0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    visible: textField.displayText !== ""

                    onClicked: {
                        textField.text = ""
                        textField.focus = false
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1.1
                color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                border.color: "transparent"
            }
        }

        footer: Item {
            id: footer
            width: parent.width
            implicitHeight: mainWindow.visibility === 5 ? messageRow.height : messageRow.height + 2 * mainView.innerSpacing
            z: 2

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 250.0
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Universal.background
                opacity: mainView.backgroundOpacity
                border.color: Universal.background
            }

            Row {
                id: messageRow
                width: parent.width
                anchors.top: parent.top
                leftPadding: mainView.innerSpacing
                rightPadding: mainView.innerSpacing
                visible: conversationPage.phoneNumber !== undefined || currentConversationMode === mainView.conversationMode.Thread

                Button {
                    id:attachmentButtonAdd
                    flat:true
                    visible: imagePicker.imageUrl === ""
                    bottomPadding: 10
                    anchors.bottom: parent.bottom
                    contentItem: Image {
                        id: attachmentIconAdd
                        source: Qt.resolvedUrl("/icons/attachment@4x.png")
                        fillMode: Image.PreserveAspectFit

                        ColorOverlay {
                            anchors.fill: attachmentIconAdd
                            source: attachmentIconAdd
                            color: mainView.fontColor
                        }
                    }
                    background: Rectangle {
                        color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                        border.color: "transparent"
                    }
                    onClicked: {
                        if (imagePicker.imageUrl === "") {
                            mainView.keepLastIndex = true
                            console.log("Conversation | Pick image")
                            imagePicker.pickImage()
                        }
                    }
                }

                Button {
                    id: attachmentButtonRmmove
                    flat:true
                    bottomPadding: 10
                    visible: imagePicker.imageUrl !== ""
                    anchors.bottom: parent.bottom
                    contentItem: Image {
                        id: attachmentIconRemove
                        source: Qt.resolvedUrl("/icons/trash@4x.png")
                        fillMode: Image.PreserveAspectFit

                        ColorOverlay {
                            anchors.fill: attachmentIconRemove
                            source: attachmentIconRemove
                            color: mainView.fontColor
                        }
                    }
                    background: Rectangle {
                        color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                        border.color: "transparent"
                    }
                    onClicked: {
                        imagePicker.imageUrl = ""
                    }
                }

                Column {
                    id: contentColumn
                    width: parent.width - (2 * mainView.innerSpacing) - sendButton.width - attachmentButtonAdd.width
                    leftPadding: conversationPage.innerSmallSpacing
                    rightPadding: conversationPage.innerSmallSpacing
                    anchors.bottom: parent.bottom

                    TextArea {
                        id: textArea
                        width: contentColumn.width
                        leftPadding: 0
                        rightPadding: 0
                        bottomPadding: 0
                        placeholderText: qsTr("Type your message")
                        color: mainView.fontColor
                        placeholderTextColor: "darkgrey"
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
                        inputMethodHints: Qt.ImhNoPredictiveText
                        background: Rectangle {
                            color: mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
                            border.color: "transparent"
                        }
                    }
                    Row {
                        id: attachment
                        width: parent.width
                        topPadding: innerSmallSpacing * 2
                        bottomPadding: imagePicker.imageUrl !== "" ? innerSmallSpacing : 0

                        Image {
                            id: attachedImage
                            source: imagePicker.imageUrl
                            width: parent.width / 3
                            height: parent.width / 3
                            visible: imagePicker.imageUrl !== ""
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }

                Button {
                    id: sendButton
                    flat: true
                    anchors.bottom: parent.bottom
                    bottomPadding: 10
                    enabled: textArea.text.length > 0 || imagePicker.imageUrl.length > 0
                    opacity: enabled ? 1.0 : 0.3
                    contentItem: Image {
                        id: sendIcon
                        verticalAlignment: Image.AlignBottom
                        source: Qt.resolvedUrl("/icons/send_icon_light@4x.png")
                        fillMode: Image.PreserveAspectFit

                        ColorOverlay {
                            anchors.fill: sendIcon
                            source: sendIcon
                            color: mainView.fontColor
                        }
                    }
                    background: Rectangle {
                        color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                        border.color: "transparent"
                    }
                    onClicked: {
                        console.log("Conversation | Send button clicked")
                        console.log("Conversation | Number: " + conversationPage.phoneNumber)
                        console.log("Conversation | Text: " + textArea.text)
                        console.log("Conversation | Image: " + imagePicker.imageUrl)

                        var d = new Date()
                        var kind = imagePicker.imageUrl !== undefined && imagePicker.imageUrl.length > 0 ? "MMS" : "SMS"

                        var messageToSend = {"text": textArea.text, "attachmentUrl": decodeURIComponent(imagePicker.imageUrl)}

                        if (conversationPage.lastMessageIsFromSignal()) {
                            kind = "Signal"
                            switch (currentConversationMode) {
                                case mainView.conversationMode.Person:
                                    messageToSend.person = headline.text
                                    messageToSend.number = conversationPage.phoneNumber
                                    break;
                                case mainView.conversationMode.Thread:
                                    messageToSend.thread_id = currentId
                                    break;
                                default:
                                    console.log("Conversation | Unknown conversation mode")
                                    break;
                            }
                            AN.SystemDispatcher.dispatch("volla.launcher.signalSendMessageAction", messageToSend)
                        } else {
                            messageToSend.number = conversationPage.phoneNumber
                            AN.SystemDispatcher.dispatch("volla.launcher.messageAction", messageToSend)
                        }

                        // Todo: Only add message to list view, if massage was successfully sent.
                        textInputField.text = ""
                        var newMessage = new Object
                        newMessage.m_IS_SENT = true
                        newMessage.m_TEXT = textArea.text
                        newMessage.m_STEXT = mainView.parseTime(d.valueOf()) + " • " + kind
                        newMessage.m_KIND = kind
                        newMessage.m_DATE = d.valueOf().toString()
                        newMessage.m_IMAGE = imagePicker.imageUrl
                        currentConversationModel.modelArr.push(newMessage)
                        currentConversationModel.update(textInput)
                        textArea.text = ""
                        textArea.focus = false
                        imagePicker.imageUrl = ""
                        listView.positionViewAtEnd()
                    }
                }
            }
        }

        model: currentConversationModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: messageBox.height + mainView.innerSpacing

            Rectangle {
                id: messageBox
                color: "transparent"
                width: parent.width
                implicitHeight: messageColumn.height

                function parseMessage(message) {
                    var urlRegex = /(https?:\/\/)?([\da-zA-ZÀ-ž-]+\.)+([a-z]{2,6})([\/\w-]*[^\s\.]*)/g;
                    return message.replace(urlRegex, function(url,b,c) {
                        console.log("b: " + b)
                        console.log("c: " + c)
                        var url2 = b === undefined ?  'https://' + url : url;
                        return '<a href="' +url2+ '" target="_blank">' + url + '</a>';
                    })
                }

                Column {
                    id: messageColumn
                    spacing: 6.0
                    width: parent.width

                    Label {
                        id: receivedMessage
                        anchors.left: parent.left
                        topPadding: mainView.innerSpacing
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        width: messageBox.width * widthFactor
                        text: model.m_TEXT !== undefined ? messageBox.parseMessage(model.m_TEXT) : ""
                        linkColor: "lightgrey"
                        lineHeight: 1.1
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
                        visible: !model.m_IS_SENT && model.m_TEXT !== undefined
                        onLinkActivated: {
                            console.log("Conversation | Link clicked: " + link)
                            Qt.openUrlExternally(link)
                        }
                    }
                    Label {
                        anchors.left: parent.left
                        id: receivedDate
                        topPadding: model.m_TEXT === undefined ? mainView.innerSpacing : 0
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: model.m_IMAGE === undefined ? 0 : 6.0
                        width: messageBox.width * widthFactor
                        text: model.m_STEXT
                        font.pointSize: mainView.smallFontSize
                        clip: true
                        opacity: 0.7
                        visible: !model.m_IS_SENT
                    }
                    Label {
                        id: sentMessage
                        anchors.right: parent.right
                        topPadding: mainView.innerSpacing
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        width: messageBox.width * widthFactor
                        text: model.m_TEXT !== undefined ? messageBox.parseMessage(model.m_TEXT) : ""
                        linkColor: "lightgrey"
                        lineHeight: 1.1
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                        horizontalAlignment: Text.AlignRight
                        visible: model.m_IS_SENT && model.m_TEXT !== undefined
                        onLinkActivated: {
                            console.log("Conversation | Link clicked: " + link)
                            Qt.openUrlExternally(link)
                        }
                    }
                    Label {
                        id: sentDate
                        anchors.right: parent.right
                        topPadding: model.m_TEXT === undefined ? mainView.innerSpacing : 0
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: model.m_IMAGE === undefined ? 0 : 6.0
                        width: messageBox.width * widthFactor
                        text: model.m_STEXT
                        font.pointSize: mainView.smallFontSize
                        clip: true
                        opacity: 0.7
                        horizontalAlignment: Text.AlignRight
                        visible: model.m_IS_SENT
                    }
                    Image {
                        id: messageImage
                        x: model.m_IS_SENT ? messageBox.width * (1 -  widthFactor) + mainView.innerSpacing : mainView.innerSpacing
                        horizontalAlignment: Image.AlignLeft
                        width: model.m_ERROR === undefined ? messageBox.width * widthFactor : messageBox.width * 0.6
                        source: model.m_IMAGE
                        fillMode: Image.PreserveAspectFit

                        Desaturate {
                            anchors.fill: messageImage
                            source: messageImage
                            desaturation: 1.0
                        }
                    }
                    Label {
                        id: errorMessage
                        anchors.left: parent.left
                        topPadding: 6.0
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: 6.0
                        width: messageBox.width * widthFactor
                        text: model.m_ERROR !== undefined ? model.m_ERROR : ""
                        font.pointSize: mainView.smallFontSize
                        color: mainView.accentColor
                        clip: true
                        opacity: 0.5
                        horizontalAlignment: Text.AlignLeft
                        visible: model.m_ERROR !== undefined
                    }
                }
            }

            onClicked: {
                // Open message thread in app
                console.debug("Conversation | Will open conversation for " + conversationPage.phoneNumber)
                if (conversationPage.phoneNumber !== undefined && model.m_STEXT.endsWith("Signal")) {
                    AN.SystemDispatcher.dispatch("volla.launcher.signalSendMessageAction", {"number": conversationPage.phoneNumber})
                } else {
                    AN.SystemDispatcher.dispatch("volla.launcher.showSmsTreadAction", {"number": conversationPage.phoneNumber})
                }
            }
        }
    }

    ListModel {
        id: personContentModel

        property var modelArr: new Array

        function loadData() {
            console.log("Conversation | Load data for person's content")

            conversationPage.messages.forEach(function (message, index) {
                var cMessage = {m_ID: "message." + message["id"]}

                cMessage.m_TEXT = message["body"]

                if (message["isSignal"] === true) {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • Signal"
                } else if (message["isMMS"] === true) {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • MMS"
                } else {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • SMS"
                }

                cMessage.m_IS_SENT = message["isSent"]

                if (message["isSent"]) {
                    conversationPage.phoneNumber = message["address"]
                }

                if (message["image"] !== undefined && message["image"].length > 100) {
                    cMessage.m_IMAGE = "data:image/png;base64," + message["image"]
                } else if (message["errorProperty"] !== undefined && message["errorProperty"]["code"] === 403) {
                    cMessage.m_IMAGE = mainView.backgroundColor === "white" ? Qt.resolvedUrl("/images/open-in-signal_light@2x.png")
                                                                            : Qt.resolvedUrl("/images/open-in-signal_dark@2x.png")
                    cMessage.m_ERROR = qsTr("Attached image is not available for preview")
                } else {
                    cMessage.m_IMAGE = ""
                }

                if (message["partIds"] !== undefined) {
                    AN.SystemDispatcher.dispatch("volla.launcher.mmsImageAction", {"messageId": cMessage.m_ID, "partIds": message["partIds"]})
                }

                cMessage.m_DATE = message["date"]

                modelArr.push(cMessage)
            })

            conversationPage.calls.forEach(function (call, index) {
                var cCall = {m_ID: "call." + call["id"]}

                cCall.m_STEXT = mainView.parseTime(Number(call["date"])) + " • Call"
                cCall.m_IS_SENT = call["isSent"]
                cCall.m_DATE = call["date"]
                cCall.m_IMAGE = ""

                modelArr.push(cCall)
            })
        }

        function update(text) {
            console.log("Conversation | Update person's content with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Conversation | people's content model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].m_ID
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Conversation | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).m_ID
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).m_ID
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Conversation | Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            for (modelItemName in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Conversation | Will append " + filteredModelItem.m_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }

            conversationPage.sortListModel()
        }

        function executeSelection(item, typ) {
            mainView.showToast(qsTr("Not yet supported"))
        }
    }

    ListModel {
        id: threadContentModel

        property var modelArr: []

        function loadData() {
            console.log("Conversation | Load data for thread content")

            conversationPage.messages.forEach(function (message, index) {
                var cMessage = {m_ID: message["id"]}

                cMessage.m_TEXT = message["body"]

                if (message["isMMS"] === true) {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • MMS"
                } else if (message["isSignal"] === true) {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • Signal"
                } else {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • SMS"
                }

                cMessage.m_IS_SENT = message["isSent"]

                if (!message["isSent"]) {
                    conversationPage.phoneNumber = message["address"]
                }

                //console.debug("Conversation | Error: " + message["errorProperty"]["code"])
                //console.debug("Conversation | Color: " + mainView.backgroundColor)

                if (message["image"] !== undefined && message["image"].length > 100) {
                    cMessage.m_IMAGE = "data:image/png;base64," + message["image"]
                } else if (message["errorProperty"] !== undefined && message["errorProperty"]["code"] === "403") {
                    cMessage.m_IMAGE = mainView.backgroundColor === "white" ? Qt.resolvedUrl("/images/open-in-signal_light@2x.png")
                                                                            : Qt.resolvedUrl("/images/open-in-signal_dark@2x.png")
                    cMessage.m_ERROR = qsTr("Attached image is not available for preview")
                } else {
                    cMessage.m_IMAGE = ""
                }

                if (message["partIds"] !== undefined) {
                    AN.SystemDispatcher.dispatch("volla.launcher.mmsImageAction", {"messageId": cMessage.m_ID, "partIds": message["partIds"]})
                }

                cMessage.m_DATE = message["date"]

                modelArr.push(cMessage)
            })
        }

        function update (text) {
            console.log("Conversation | Update model with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Conversation | Model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].m_ID
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).m_ID
                existingGridDict[modelItemName] = true
            }

            // Remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).m_ID
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Conversation | Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // Add new items
            for (modelItemName in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Conversation | Will append " + filteredModelItem.m_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }

            conversationPage.sortListModel()
        }

        function executeSelection(item, type) {
            mainView.showToast(qsTr("Not yet supported"))
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.conversationResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.messages = conversationPage.messages.concat(message["messages"])
//                message["messages"].forEach(function (message, index) {
//                    for (const [messageKey, messageValue] of Object.entries(message)) {
//                        console.log("Conversation | * " + messageKey + ": " + messageValue)
//                    }
//                })
                conversationPage.updateListModel()
            } else if (type === "volla.launcher.signalMessagesResponse") {
                console.log("Conversation | onDispatched: " + type)
                var previousMessage
                message["messages"].forEach(function (signalMessage, index) {
                    signalMessage["isSignal"] = true
                    previousMessage = signalMessage
//                    for (const [messageKey, messageValue] of Object.entries(signalMessage)) {
//                        console.log("Conversation | * " + messageKey + ": \"" + messageValue + "\": " + typeof messageValue)
//                    }
                })
                conversationPage.messages = conversationPage.messages.concat(message["messages"])
                conversationPage.updateListModel()
            } else if (type === "volla.launcher.callConversationResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.calls = conversationPage.calls.concat(message["calls"])
//                message["calls"].forEach(function (call, index) {
//                    for (const [callKey, callValue] of Object.entries(call)) {
//                        console.log("Collections | * " + callKey + ": " + callValue)
//                    }
//                })
                conversationPage.updateListModel()
            } else if (type === "volla.launcher.mmsImageResponse") {
                console.log("Conversation | onDispatched: " + type)
                if (message["hasImage"]) {
                    conversationPage.updateImage(message["messageId"], message["image"])
                }
            } else if (type === "volla.launcher.signalSendMessagesResponse") {
                console.log("Conversation | onDispatched: " + type)
                if (!message["isSent"])
                    mainView.showToast(qsTr("Message not sent") + ": " + message["message"])
            } else if (type === "volla.launcher.navBarResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.navBarHeight = message["height"] / Screen.pixelDensity
            }
        }
    }

    // @disable-check M300
    AN.ImagePicker {
        id: imagePicker
        multiple: false

        onReady: {
            console.log("Conversation | Image selection received")
        }
    }
}
