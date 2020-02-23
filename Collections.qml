import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.13
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12

Page {
    id: collectionPage
    anchors.fill: parent

    property var headline
    property var textInputField
    property string textInput
    property real iconSize: 64.0
    property int currentCollectionMode: 3
    property var currentCollectionModel: peopleModel

    property string cTITLE:  "title"   // large main title, bold
    property string cSTITLE: "stitle"  // small title above the main, grey
    property string cTEXT:   "text"    // large main text, regular
    property string cSTEXT:  "stext"   // small text beyond the main text, grey
    property string cICON:   "icon"    // small icon at the left side
    property string cIMAGE:  "image"   // preview image
    property string cBADGE:  "badge"   // red dot for unread content children
    property string cSBADGE: "sbadge"  // red dot for unsead messages

    onTextInputChanged: {
        console.log("text input changed")
        currentCollectionModel.update(textInput)
    }

    Component.onCompleted: {
        textInput.text = ""
        currentCollectionModel.update("")
    }

    function updateCollectionMode (mode) {
        console.log("update collection model: " + mode)

        if (mode !== currentCollectionMode) {
            currentCollectionMode = mode

            switch (mode) {
                case swipeView.collectionMode.People:
                    headline.text = qsTr("People")
                    textInputField.placeholderText = "Find poeple ..."
                    currentCollectionModel = peopleModel
                    break;
                case swipeView.collectionMode.Threads:
                    headline.text = qsTr("Threads")
                    textInputField.placeholderText = "Find thread ..."
                    currentCollectionModel = threadModel
                    break;
                case swipeView.collectionMode.News:
                    headline.text = qsTr("News")
                    textInputField.placeholderText = "Find news ..."
                    currentCollectionModel = newsModel
                    break;
                default:
                    console.log("Unknown collection mode")
                    break;
            }
            currentCollectionModel.update(textInput)
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
                    text: qsTr("Collection")
                    font.pointSize: swipeView.headerPointSize
                    font.weight: Font.Black
                    Binding {
                        target: collectionPage
                        property: "headline"
                        value: headerLabel
                    }
                }
                TextField {
                    id: textField
                    padding: swipeView.innerSpacing
                    x: swipeView.innerSpacing
                    width: parent.width -swipeView.innerSpacing * 2
                    placeholderText: qsTr("Filter collections")
                    color: Universal.foreground
                    placeholderTextColor: "darkgrey"
                    font.pointSize: swipeView.pointSize
                    leftPadding: 0.0
                    rightPadding: 0.0
                    background: Rectangle {
                        color: "black"
                        border.color: "transparent"
                    }

                    Binding {
                        target: collectionPage
                        property: "textInput"
                        value: textField.displayText.toLowerCase()
                    }

                    Binding {
                        target: collectionPage
                        property: "textInputField"
                        value: textField
                    }

                    Button {
                        id: deleteButton
                        visible: textField.activeFocus
                        text: "<font color='#808080'>×</font>"
                        font.pointSize: swipeView.pointSize * 2
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

        model: currentCollectionModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: contactBox.height

            property var selectedMenuItem: contactBox
            property bool isMenuStatus: false

            Rectangle {
                id: contactBox
                color: "transparent"
                width: parent.width
                implicitHeight: contactMenu.visible ? contactRow.height + contactMenu.height + swipeView.innerSpacing : contactRow.height + swipeView.innerSpacing

                Row {
                    id: contactRow
                    x: swipeView.innerSpacing
                    spacing: 18.0
                    topPadding: swipeView.innerSpacing / 2

                    // todo: handle no image

                    Image {
                        id: contactImage
                        source: model.cICON !== undefined ? model.cICON : ""
                        sourceSize: Qt.size(collectionPage.iconSize, collectionPage.iconSize)
                        smooth: true
                        visible: false

                        Desaturate {
                            anchors.fill: contactImage
                            source: contactImage
                            desaturation: 1.0
                        }
                    }
                    Image {
                        source: "/images/contact-mask.png"
                        id: contactMask
                        sourceSize: Qt.size(collectionPage.iconSize, collectionPage.iconSize)
                        smooth: true
                        visible: false
                    }
                    OpacityMask {
                        id: iconMask
                        width: collectionPage.iconSize
                        height: collectionPage.iconSize
                        source: contactImage
                        maskSource: contactMask
                        visible: model.cICON !== undefined
                    }
                    Column {
                        spacing: 3.0
                        Label {
                            id: sourceLabel
                            topPadding: model.cSTITLE !== undefined ? 8.0 : 0.0
                            width: contactBox.width - swipeView.innerSpacing * 2 - collectionPage.iconSize - contactRow.spacing
                            text: model.cSTITLE !== undefined ? model.cSTITLE : ""
                            font.pointSize: swipeView.smallPointSize
                            lineHeight: 1.1
                            wrapMode: Text.Wrap
                            opacity: 0.8
                            visible: model.cSTITLE !== undefined
                        }
                        Label {
                            id: titleLabel
                            topPadding: model.cTITLE !== undefined ? 8.0 : 0.0
                            width: contactBox.width - swipeView.innerSpacing * 2 - collectionPage.iconSize - contactRow.spacing
                            text: model.cTITLE !== undefined ? model.cTITLE : ""
                            font.pointSize: swipeView.pointSize
                            font.weight: Font.Black
                            visible: model.cTITLE !== undefined

                            LinearGradient {
                                id: titleLabelTruncator
                                height: titleLabel.height
                                width: titleLabel.width
                                start: Qt.point(titleLabel.width - swipeView.innerSpacing,0)
                                end: Qt.point(titleLabel.width,0)
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: "#00000000"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: backgroundItem.isMenuStatus ? Universal.accent : Universal.background
                                    }
                                }
                            }
                        }
                        Label {
                            id: textLabel
                            width: contactBox.width - swipeView.innerSpacing * 2 - collectionPage.iconSize
                            text: model.cTEXT !== undefined ? model.cTEXT : ""
                            font.pointSize: swipeView.pointSize
                            lineHeight: 1.1
                            opacity: 0.9
                            wrapMode: Text.WordWrap
                            visible: model.cTEXT !== undefined
                        }
                        Row {
                            id: statusRow
                            spacing: 8.0
                            Rectangle {
                                id: statusBadge
                                visible: model.cSBADGE !== undefined ? model.cSBADGE : false
                                width: swipeView.smallPointSize * 0.6
                                height: swipeView.smallPointSize * 0.6
                                y: swipeView.smallPointSize * 0.3
                                radius: height * 0.5
                                color: backgroundItem.isMenuStatus ? Universal.background : Universal.accent
                            }
                            Label {
                                id: statusLabel
                                bottomPadding:  model.cIMAGE !== undefined ? swipeView.innerSpacing : 0.0
                                width: statusBadge.visible ?
                                           contactBox.width - swipeView.innerSpacing * 2 - collectionPage.iconSize - contactRow.spacing - statusBadge.width - statusRow.spacing
                                         : contactBox.width - swipeView.innerSpacing * 2 - collectionPage.iconSize - contactRow.spacing
                                text: model.cSTEXT !== undefined ? model.cSTEXT : ""
                                font.pointSize: swipeView.smallPointSize
                                clip: true
                                opacity: 0.8
                                visible: model.cSTEXT !== undefined

                                LinearGradient {
                                    id: statusLabelTruncator
                                    height: statusLabel.height
                                    width: statusLabel.width
                                    start: Qt.point(statusLabel.width - swipeView.innerSpacing,0)
                                    end: Qt.point(statusLabel.width,0)
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: "#00000000"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: backgroundItem.isMenuStatus ? Universal.accent : Universal.background
                                        }
                                    }
                                }
                            }
                        }
                        Image {
                            id: newsImage
                            width: contactBox.width - swipeView.innerSpacing - collectionPage.iconSize - contactRow.spacing
                            source: model.cIMAGE !== undefined ? model.cIMAGE : ""
                            fillMode: Image.PreserveAspectFit

                            Desaturate {
                                anchors.fill: newsImage
                                source: newsImage
                                desaturation: 1.0
                            }
                        }
                    }                    
                }
                Rectangle {
                    id: notificationBadge
                    anchors.top: contactBox.top
                    anchors.topMargin: swipeView.innerSpacing * 0.5
                    anchors.left: contactBox.left
                    anchors.leftMargin: swipeView.innerSpacing
                    visible: model.cBADGE !== undefined ? model.cBADGE : false
                    width: collectionPage.iconSize * 0.25
                    height: collectionPage.iconSize * 0.25
                    radius: height * 0.5
                    color: Universal.accent
                }
                Column {
                    id: contactMenu
                    anchors.top: contactRow.bottom
                    topPadding: 22.0
                    bottomPadding: 8.0
                    leftPadding: swipeView.innerSpacing
                    spacing: 14.0
                    visible: false
                    Label {
                        id: callLabel
                        height: swipeView.mediumPointSize * 1.2
                        text: qsTr("Call")
                        font.pointSize: swipeView.mediumPointSize
                    }
                    Label {
                        id: messageLabel
                        height: swipeView.mediumPointSize * 1.2
                        text: qsTr("Send Message")
                        font.pointSize: swipeView.mediumPointSize
                    }
                    Label {
                        id: emailLabel
                        height: swipeView.mediumPointSize * 1.2
                        text: qsTr("Send Email")
                        font.pointSize: swipeView.mediumPointSize
                    }
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 250.0
                }
            }

            onClicked: {
                console.log("List entry '" + model.cTITLE + "' clicked.")
                var imPoint = mapFromItem(iconMask, 0, 0)
                    currentCollectionModel.executeSelection(model, swipeView.actionType.ShowGroup)
                if (currentCollectionMode === swipeView.collectionMode.News
                        && mouseY > imPoint.y && mouseY < imPoint.y + iconMask.height
                        && mouseX > imPoint.x && mouseX < imPoint.x + iconMask.width) {
                    currentCollectionModel.executeSelection(model, swipeView.actionType.ShowGroup)
                } else {
                    // todo: should be replaced by model id
                    currentCollectionModel.executeSelection(model.cTITLE, swipeView.actionType.ShowDetails)
                }
            }
            onPressAndHold: {
                if (currentCollectionMode === swipeView.collectionMode.People) {
                    contactMenu.visible = true
                    contactBox.color = Universal.accent
                    preventStealing = true
                    isMenuStatus = true
                    backgroundItem.executeSelection()
                }
            }
            onExited: {
                if (currentCollectionMode === swipeView.collectionMode.People) {
                    contactMenu.visible = false
                    contactBox.color = "transparent"
                    preventStealing = false
                    isMenuStatus = false
                    backgroundItem.executeSelection()
                }
            }
            onMouseYChanged: {
                console.log("Content menua mouse y changed to: " + mouse.y)
                var plPoint = mapFromItem(callLabel, 0, 0)
                var mlPoint = mapFromItem(messageLabel, 0, 0)
                var elPoint = mapFromItem(emailLabel, 0, 0)

                if (mouseY > plPoint.y && mouseY < plPoint.y + callLabel.height) {
                    selectedMenuItem = callLabel
                } else if (mouseY > mlPoint.y && mouseY < mlPoint.y + messageLabel.height) {
                    selectedMenuItem = messageLabel
                } else if (mouseY > elPoint.y && mouseY < elPoint.y + emailLabel.height) {
                    selectedMenuItem = emailLabel
                } else {
                    selectedMenuItem = contactBox
                }
            }
            onSelectedMenuItemChanged: {
                callLabel.font.bold = selectedMenuItem === callLabel
                callLabel.font.pointSize = selectedMenuItem === callLabel ? swipeView.mediumPointSize * 1.2 : swipeView.mediumPointSize
                messageLabel.font.bold = selectedMenuItem === messageLabel
                messageLabel.font.pointSize = selectedMenuItem === messageLabel ? swipeView.mediumPointSize * 1.2 : swipeView.mediumPointSize
                emailLabel.font.bold = selectedMenuItem === emailLabel
                emailLabel.font.pointSize = selectedMenuItem === emailLabel ? swipeView.mediumPointSize * 1.2 : swipeView.mediumPointSize
            }

            function executeSelection() {
                if (selectedMenuItem === callLabel) {
                    console.log("Call " + model.cTITLE)
                    currentCollectionModel.executeSelection(model, swipeView.actionType.MakeCall)
                } else if (selectedMenuItem === messageLabel) {
                    console.log("Send message to " + model.cTITLE)
                    currentCollectionModel.executeSelection(model, swipeView.actionType.SendSMS)
                } else if (selectedMenuItem === emailLabel) {
                    console.log("Send email to " + model.cTITLE)
                    currentCollectionModel.executeSelection(model, swipeView.actionType.SendEmail)
                } else {
                    console.log("Nothing selected")
                }
            }
        }
    }

    ListModel {
        id: peopleModel

        property var modelArr: [{cTITLE: "Max Miller", cSTEXT: "Hello World Ltd.", cICON: "/images/contact-max-miller.jpg"},
                                {cTITLE: "Paula Black", cSTEXT: "How are you? This is a very long status text, that needs to be truncated", cICON: "/images/contact-paula-black.jpg", cSBADGE: true}]

        function update(text) {
            console.log("Update model with text input: " + text)

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Model has " + modelArr.length + "elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].cTITLE
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).cTITLE
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).cTITLE
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Remove " + modelItemName)
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
                    console.log("Will append " + filteredModelItem.cTITLE)
                    append(filteredModelDict[modelItemName])
                }
            }
        }

        function executeSelection(item, type) {
            switch (type) {
                case swipeView.actionType.MakeCall:
                    Qt.openUrlExternally("tel:+491772558379")
                    break
                case swipeView.actionType.SendSMS:
                    Qt.openUrlExternally("sms:+491772558379")
                    break
                case swipeView.actionType.SendEmail:
                    Qt.openUrlExternally("mailto:info@volla.online")
                    break
                default:
                    swipeView.updateDetailPage("/images/contactTimeline.png", item, qsTr("Filter content ..."))
            }
        }
    }

    ListModel {
        id: threadModel

        property var modelArr: [{cTITLE: "Julia Herbst", cTEXT: "Hello, have you read my ideas about the project?", cSTEXT: "1h ago • SMS"},
                                {cTITLE: "Pierre Vaillant", cTEXT: "First Studio recodings of Pink Elepants", cSTEXT: "Yesterday, 17:56 • Email"}]

        function update (text) {
            console.log("Update model with text input: " + text)

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Model has " + modelArr.length + "elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].cTEXT
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).cTEXT
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).cTEXT
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Remove " + modelItemName)
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
                    console.log("Will append " + filteredModelItem.cTEXT)
                    append(filteredModelDict[modelItemName])
                }
            }
        }

        function executeSelection(item, typ) {

        }
    }

    ListModel {
        id: newsModel

        property var modelArr: [{cSTITLE: "The New York Times • Feed", cTEXT: "What Makes People Charismatic and How You Can Be, Too", cSTEXT: "14 Min ago", cICON: "/images/news-ny-times.png", cBADGE: true},
                                {cSTITLE: "Ben Rogers\n@brogers • Twitter", cTEXT: "Impressive view from the coars of the lake Juojärvi in Finnland :)", cSTEXT: "1h ago", cICON: "/images/news-ben-rogers.jpg", cIMAGE: "/images/news-image.png", cBADGE: false}]

        function update (text) {
            console.log("Update model with text input: " + text)

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Model has " + modelArr.length + "elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].cTEXT
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).cTEXT
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).cTEXT
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Remove " + modelItemName)
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
                    console.log("Will append " + filteredModelItem.cTEXT)
                    append(filteredModelDict[modelItemName])
                }
            }
        }

        function executeSelection(item, type) {
            if (type === swipeView.actionType.ShowGroup) {
                console.log("Group view not implemented yet")
            } else {
                swipeView.updateDetailPage("/images/newsDetail01.png", "", "")
            }
        }
    }
}
