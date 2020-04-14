import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.13
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

Page {
    id: conversationPage
    anchors.fill: parent

    property var headline
    property var textInputField
    property string textInput
    property real widthFactor: 0.9
    property int threadAge: 84000 * 7 // one week in seconds

    property int currentConversationMode: 0
    property var currentId: 0
    property var currentConversationModel: personContentModel
    property var messages: new Array
    property var calls: new Array

    property string c_ID:        "id"      // the id of the message or content
    property string c_TEXT:      "text"    // large main text, regular
    property string c_STEXT:     "stext"   // small text beyond the main text, grey
    property string c_IMAGE:     "image"   // preview image
    property string c_IS_SENT:   "sent"    // true if the content was sent by user
    property string c_KIND:      "kind"    // kind of content like sms or mms
    property string c_DATE:      "date"    // date in milliseconds of the item

    onTextInputChanged: {
        console.log("Conversation | text input changed")
        currentConversationModel.update(textInput)
    }

    Component.onCompleted: {
        textInput.text = ""
        currentConversationModel.update("")
    }

    function updateConversationPage (mode, id, name) {
        console.log("Conversation | Update conversation mode: " + mode + " with id " + id)

        if (mode !== currentConversationMode || currentId !== id) {
            currentConversationMode = mode
            currentConversationModel.clear()
            currentConversationModel.modelArr = new Array

            switch (mode) {
                case swipeView.conversationMode.Person:
                    headline.text = name
                    currentId = id
                    currentConversationModel = personContentModel
                    loadConversation({"personId": id})
                    loadCalls({"match": name})
                    break;
                case swipeView.conversationMode.Thread:
                    headline.text = name
                    currentId = id
                    currentConversationModel = threadContentModel
                    loadConversation({"threadId": id})
                    break;
                default:
                    console.log("Conversation | Unknown conversation mode")
                    break;
            }
        }
    }

    function loadConversation(filter) {
        console.log("Conversations | Will load messages")
        // Todo: Update messages
        messages = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.conversationAction", filter)
    }

    function loadCalls(filter) {
        console.log("Conversations | Will load calls")
        // Todo: Update calls
        calls = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.callConversationAction", filter)
    }

    // Todo: Improve display date and time
    function parseTime(timeInMillis) {
        var now = new Date()
        var date = new Date(timeInMillis)
        var today = new Date()
        today.setHours(0)
        today.setMinutes(0)
        today.setMilliseconds(0)
        var yesterday = new Date()
        yesterday.setHours(0)
        yesterday.setMinutes(0)
        yesterday.setMilliseconds(0)
        yesterday = new Date(yesterday.valueOf() - 84000 * 1000)
        var timeDelta = (now.valueOf() - timeInMillis) / 1000 / 60
        if (timeDelta < 1) {
            return qsTr("Just now")
        } else if (timeDelta < 60) {
            return Math.floor(timeDelta) + " " + qsTr("minutes ago")
        } else if (date.valueOf() > today.valueOf()) {
            if (date.getMinutes() < 10) {
                return qsTr("Today") + " " + date.getHours() + ":0" + date.getMinutes()
            } else {
                return qsTr("Today") + " " + date.getHours() + ":" + date.getMinutes()
            }
        } else if (date.valueOf() > yesterday.valueOf()) {
            if (date.getMinutes() < 10) {
                return qsTr("Yesterday") + " " + date.getHours() + ":0" + date.getMinutes()
            } else {
                return qsTr("Yesterday") + " " + date.getHours() + ":" + date.getMinutes()
            }
        } else if (date.getMinutes() < 10) {
            return date.toLocaleDateString() + " " + date.getHours() + ":0" + date.getMinutes()
        } else {
            return date.toLocaleDateString() + " " + date.getHours() + ":" + date.getMinutes()
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        headerPositioning: ListView.PullBackHeader

        header: Rectangle {
            id: header
            color: Universal.background
            width: parent.width
            implicitHeight: headerColumn.height
            Column {
                id: headerColumn
                width: parent.width
                Label {
                    id: headerLabel
                    topPadding: swipeView.innerSpacing
                    x: swipeView.innerSpacing
                    text: qsTr("Conversation")
                    font.pointSize: swipeView.headerFontSize
                    font.weight: Font.Black
                    Binding {
                        target: conversationPage
                        property: "headline"
                        value: headerLabel
                    }
                }
                TextField {
                    id: textField
                    padding: swipeView.innerSpacing
                    x: swipeView.innerSpacing
                    width: parent.width -swipeView.innerSpacing * 2
                    placeholderText: qsTr("Filter messages ...")
                    color: Universal.foreground
                    placeholderTextColor: "darkgrey"
                    font.pointSize: swipeView.largeFontSize
                    leftPadding: 0.0
                    rightPadding: 0.0
                    background: Rectangle {
                        color: "black"
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
                        visible: textField.activeFocus
                        text: "<font color='#808080'>×</font>"
                        font.pointSize: swipeView.largeFontSize * 2
                        flat: true
                        topPadding: 0.0
                        anchors.top: parent.top
                        anchors.right: parent.right

                        onClicked: {
                            textField.text = ""
                            textField.activeFocus = false
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    border.color: Universal.background
                    color: "transparent"
                    height: 1.1
                }
            }
        }

        model: currentConversationModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: messageBox.height + swipeView.innerSpacing

            Rectangle {
                id: messageBox
                color: "transparent"
                width: parent.width
                implicitHeight: messageColumn.height

                Column {
                    id: messageColumn
                    spacing: 6.0
                    width: parent.width

                    Label {
                        id: receivedMessage
                        anchors.left: parent.left
                        topPadding: swipeView.innerSpacing
                        leftPadding: swipeView.innerSpacing
                        rightPadding: swipeView.innerSpacing
                        width: messageBox.width * widthFactor
                        text: model.c_TEXT !== undefined ? model.c_TEXT : ""
                        lineHeight: 1.1
                        font.pointSize: swipeView.largeFontSize
                        wrapMode: Text.WordWrap
                        visible: !model.c_IS_SENT && model.c_TEXT !== undefined
                    }
                    Label {
                        anchors.left: parent.left
                        id: receivedDate
                        leftPadding: swipeView.innerSpacing
                        rightPadding: swipeView.innerSpacing
                        bottomPadding: model.c_IMAGE === undefined ? 0 : 6.0
                        width: messageBox.width * widthFactor
                        text: model.c_STEXT
                        font.pointSize: swipeView.smallFontSize
                        clip: true
                        opacity: 0.7
                        visible: !model.c_IS_SENT
                    }
                    Label {
                        id: sentMessage
                        anchors.right: parent.right
                        topPadding: swipeView.innerSpacing
                        leftPadding: swipeView.innerSpacing
                        rightPadding: swipeView.innerSpacing
                        width: messageBox.width * widthFactor
                        text: model.c_TEXT !== undefined ? model.c_TEXT : ""
                        lineHeight: 1.1
                        font.pointSize: swipeView.largeFontSize
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                        horizontalAlignment: Text.AlignRight
                        visible: model.c_IS_SENT && model.c_TEXT !== undefined
                    }
                    Label {
                        id: sentDate
                        anchors.right: parent.right
                        leftPadding: swipeView.innerSpacing
                        rightPadding: swipeView.innerSpacing
                        bottomPadding: model.c_IMAGE === undefined ? 0 : 6.0
                        width: messageBox.width * widthFactor
                        text: model.c_STEXT
                        font.pointSize: swipeView.smallFontSize
                        clip: true
                        opacity: 0.7
                        horizontalAlignment: Text.AlignRight
                        visible: model.c_IS_SENT
                    }
                    Image {
                        id: messageImage
                        x: model.c_IS_SENT ? messageBox.width * (1 -  widthFactor) + swipeView.innerSpacing : swipeView.innerSpacing
                        horizontalAlignment: Image.AlignLeft
                        width: messageBox.width * widthFactor
                        source: model.c_IMAGE !== undefined ? model.c_IMAGE : ""
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
                // Todo
            }
        }
    }

    ListModel {
        id: personContentModel

        property var modelArr: [{c_ID: "0", c_TEXT: "What you think about having lunch together in the restaurant, that opened recently", c_STEXT: "Yesterday 10:30 • SMS", c_IS_SENT: false},
                                {c_ID: "2", c_TEXT: "Sure, I would like to order a pizza with red wine and a small dessert afterwards", c_STEXT: "Yesterday 10:46 • SMS", c_IS_SENT: true},
                                {c_ID: "3", c_TEXT: "Look at this nice image", c_STEXT: "Today 14:01 • SMS", c_IS_SENT: false, c_IMAGE: "/images/news-image.png"}]

        function loadData() {
            console.log("Conversation | Load data for person's content")

            conversationPage.messages.forEach(function (message, index) {
                var cMessage = {c_ID: "message." + message["id"]}

                cMessage.c_TEXT = message["body"]

                if (message["isMMS"] === true) {
                    cMessage.c_STEXT = conversationPage.parseTime(message["date"]) + " • MMS"
                } else {
                    cMessage.c_STEXT = conversationPage.parseTime(message["date"]) + " • SMS"
                }

                cMessage.c_IS_SENT = message["isSent"]

                if (message["image"] !== undefined) {
                    cMessage.c_IMAGE = "data:image/png;base64," + message["image"]
                }

                cMessage.c_DATE = message["date"]

                modelArr.push(cMessage)
            })

            conversationPage.calls.forEach(function (call, index) {
                var cCall = {c_ID: "call." + call["id"]}

                cCall.c_STEXT = conversationPage.parseTime(call["date"]) + " • Call"
                cCall.c_IS_SENT = call["isSent"]

                modelArr.push(cCall)
            })

            modelArr.sort(function(a,b) {
                return a.c_DATE - b.c_DATE
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
                var modelItemName = modelArr[i].c_ID
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Conversation | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).c_ID
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).c_ID
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
                    console.log("Conversation | Will append " + filteredModelItem.c_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }

            listView.positionViewAtEnd()
        }

        function executeSelection(item, typ) {
            toast.show()
        }
    }

    ListModel {
        id: threadContentModel

        property var modelArr: []

        function loadData() {
            console.log("Conversation | Load data for thread content")

            conversationPage.messages.forEach(function (message, index) {
                var cMessage = {c_ID: message["id"]}

                cMessage.c_TEXT = message["body"]

                if (message["isMMS"] === true) {
                    cMessage.c_STEXT = conversationPage.parseTime(message["date"]) + " • MMS"
                } else {
                    cMessage.c_STEXT = conversationPage.parseTime(message["date"]) + " • SMS"
                }

                cMessage.c_IS_SENT = message["isSent"]

                if (message["image"] !== undefined) {
                    cMessage.c_IMAGE = "data:image/png;base64," + message["image"]
                }

                modelArr.push(cMessage)
            })

            modelArr.sort(function(a,b) {
                return a.c_DATE - b.c_DATE
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
                var modelItemName = modelArr[i].c_ID
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Conversation | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).c_ID
                existingGridDict[modelItemName] = true
            }

            // Remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).c_ID
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
                    console.log("Conversation | Will append " + filteredModelItem.c_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }

            listView.positionViewAtEnd()
        }

        function executeSelection(item, typ) {
            toast.show()
        }
    }

    AN.Toast {
        id: toast
        text: qsTr("Not yet supported")
        longDuration: true
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.conversationResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.messages = message["messages"]
                message["messages"].forEach(function (message, index) {
                    for (const [messageKey, messageValue] of Object.entries(message)) {
                        console.log("Conversation | * " + messageKey + ": " + messageValue)
                    }
                })
                conversationPage.currentConversationModel.loadData()
                conversationPage.currentConversationModel.update(conversationPage.textInput)
            } else if (type === "volla.launcher.callConversationResponse") {
                console.log("Conversation | onDispatched: " + type)
                conversationPage.calls = message["calls"]
                message["calls"].forEach(function (call, index) {
                    for (const [callKey, callValue] of Object.entries(call)) {
                        console.log("Collections | * " + callKey + ": " + callValue)
                    }
                })
                conversationPage.currentConversationModel.loadData()
                conversationPage.currentConversationModel.update(conversationPage.textInput)
            }
        }
    }
}
