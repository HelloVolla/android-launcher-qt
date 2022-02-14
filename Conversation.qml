import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.12
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

Page {
    id: conversationPage
    anchors.fill: parent

    property var headline
    property var textInputField
    property string textInput
    property string attachmentUrl: imagePicker.imageUrl
    property real widthFactor: 0.9
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
    property string m_IS_SENT:   "sent"    // true if the content was sent by user
    property string m_KIND:      "kind"    // kind of content like sms or mms
    property string m_DATE:      "date"    // date in milliseconds of the item

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
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
                    for (var i = 0; i < mainView.contacts.length; i++) {
                        var contact = mainView.contacts[i]
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
                    operationCount = 2
                    mainView.updateSpinner(true)
                    loadConversation({"personId": id, "numbers": numbers, "threadAge": threadAge})
                    loadCalls({"match": name, "age": threadAge})
                    break;
                case mainView.conversationMode.Thread:
                    headline.text = name
                    currentId = id
                    currentConversationModel = threadContentModel
                    operationCount = 1
                    mainView.updateSpinner(true)
                    loadConversation({"threadId": id, "threadAge": threadAge})
                    break;
                default:
                    console.log("Conversation | Unknown conversation mode")
                    break;
            }
        }
   }

    function updateListMocel() {
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
        console.log("Conversations | Will load messages")
        messages = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.conversationAction", filter)
    }

    function loadCalls(filter) {
        console.log("Conversation | Will load calls")
        calls = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.callConversationAction", filter)
    }

    ListView {
        id: listView
        anchors.top: parent.top
        width: parent.width
        height: parent.height
        headerPositioning: mainView.backgroundOpacity === 1.0 ? ListView.PullBackHeader : ListView.InlineHeader
        footerPositioning: mainView.backgroundOpacity === 1.0 ? ListView.OverlayFooter : ListView.InlineFooter

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

        footer: Rectangle {
            id: footer
            width: parent.width
            implicitHeight: messageRow.height + attachment.height
            color: mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
            border.color: "transparent"
            z: 2

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 250.0
                }
            }

            Column {
                width: parent.width

                Row {
                    id: messageRow
                    width: parent.width
                    padding: mainView.innerSpacing
                    visible: conversationPage.phoneNumber !== undefined

                    Button {
                        id:attachmentButton
                        flat:true
                        contentItem: Image {
                            id: attachmentIcon
                            source: imagePicker.imageUrl === "" ? Qt.resolvedUrl("/icons/attachment@4x.png") :
                                                                  Qt.resolvedUrl("/icons/trash@4x.png")
                            fillMode: Image.PreserveAspectFit

                            ColorOverlay {
                                anchors.fill: sendIcon
                                source: sendIcon
                                color: mainView.fontColor
                            }
                        }
                        onClicked: {
                            if (imagePicker.imageUrl === "") {
                                mainView.keepLastIndex = true
                                console.log("Conversation | Pick image")
                                imagePicker.pickImage()
                            } else {
                                imagePicker.imageUrl = ""
                            }
                        }
                    }
                    TextArea {
                        id: textArea
                        x: mainView.innerSpacing
                        width: messageRow.width - (mainView.innerSpacing * 2) - sendButton.width - attachmentButton.width
                        placeholderText: qsTr("Type your message")
                        color: mainView.fontColor
                        placeholderTextColor: "darkgrey"
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
                        leftPadding: 0.0
                        rightPadding: mainView.innerSpacing

                        background: Rectangle {
                            color: mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
                            border.color: "transparent"
                        }

                        onActiveFocusChanged: {
                            console.log("Conversation | On active focus changed to " + activeFocus)
                            if (activeFocus) {
                                listView.height = mainWindow.visibility === 5 ? mainView.height * 0.62 : mainView.height * 0.6
                                listView.positionViewAtEnd()
                            } else {
                                listView.height = mainView.height
                                listView.positionViewAtEnd()
                            }
                        }
                    }
                    Button {
                        id: sendButton
                        flat: true
                        enabled: textArea.text.length > 0
                        height: mainView.innerSpacing * 1.2
                        width: mainView.innerSpacing * 2
                        opacity: enabled ? 1.0 : 0.3
                        contentItem: Image {
                            id: sendIcon
                            source: Qt.resolvedUrl("/icons/send_icon_light.png")
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
                            AN.SystemDispatcher.dispatch(
                                        "volla.launcher.messageAction",
                                        {"number": conversationPage.phoneNumber, "text": textArea.text,
                                         "attachmentUrl": imagePicker.imageUrl} )

                            // Todo: Only add message to list currentConversationModel, if massage was successfully sent.
                            var d = new Date()
                            currentConversationModel.append(
                                        {"m_TEXT": textArea.text, "m_STEXT": mainView.parseTime(d.valueOf()) + " • SMS",
                                         "m_IS_SENT": true, "m_KIND": "sms", "m_DATE": d.valueOf().toString(), "m_IMAGE": imagePicker.imageUrl} )
                            textArea.text = ""
                            textArea.focus = false
                            imagePicker.imageUrl = ""
                            listView.positionViewAtEnd()
                        }
                    }
                }

                Row {
                    id: attachment
                    width: parent.width
                    leftPadding: mainView.innerSpacing + attachmentButton.width
                    rightPadding: mainView.innerSpacing + sendButton.width

                    Image {
                        source: imagePicker.imageUrl
                        width: 100
                        height: 100
                        visible: imagePicker.imageUrl !== ""
                        fillMode: Image.PreserveAspectCrop
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
                    var urlRegex = /(((https?:\/\/)|([^\s]+\.))[^\s,]+)/g;
                    return message.replace(urlRegex, function(url,b,c) {
                        var url2 = !c.startsWith('http') ?  'http://' + url : url;
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
                        width: messageBox.width * widthFactor
                        source: model.m_IMAGE // !== undefined ? model.m_IMAGE : ""
                        fillMode: Image.PreserveAspectFit

                        Desaturate {
                            anchors.fill: messageImage
                            source: messageImage
                            desaturation: 1.0
                        }
                    }
                }
            }

            onClicked: {
                // todo: do anything with the selected message
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

                if (message["isMMS"] === true) {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • MMS"
                } else {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • SMS"
                }

                cMessage.m_IS_SENT = message["isSent"]

                if (message["isSent"]) {
                    conversationPage.phoneNumber = message["address"]
                }

                if (message["image"] !== undefined) {
                    cMessage.m_IMAGE = "data:image/png;base64," + message["image"]
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
                } else {
                    cMessage.m_STEXT = mainView.parseTime(Number(message["date"])) + " • SMS"
                }

                cMessage.m_IS_SENT = message["isSent"]

                if (!message["isSent"]) {
                    conversationPage.phoneNumber = message["address"]
                }

                if (message["image"] !== undefined) {
                    cMessage.m_IMAGE = "data:image/png;base64," + message["image"]
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
                    console.log("Conversation | Add " + modelItemName + " to filtered items")
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
                conversationPage.messages.push(message["messages"])
                conversationPage.messages = message["messages"]
//                message["messages"].forEach(function (message, index) {
//                    for (const [messageKey, messageValue] of Object.entries(message)) {
//                        console.log("Conversation | * " + messageKey + ": " + messageValue)
//                    }
//                })
                conversationPage.updateListMocel()
            } else if (type === "volla.launcher.callConversationResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.calls = message["calls"]
//                message["calls"].forEach(function (call, index) {
//                    for (const [callKey, callValue] of Object.entries(call)) {
//                        console.log("Collections | * " + callKey + ": " + callValue)
//                    }
//                })
                conversationPage.updateListMocel()
            } else if (type === "volla.launcher.mmsImageResponse") {
                console.log("Conversation | onDispatched: " + type)
                if (message["hasImage"]) {
                    conversationPage.updateImage(message["messageId"], message["image"])
                }
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
