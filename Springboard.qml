import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.13
import FileIO 1.0
import com.volla.launcher.backend 1.0
import AndroidNative 1.0 as AN

Page {
    id: springBoard
    anchors.fill: parent

    property string textInput
    property bool textFocus
    property real menuheight: swipeView.largeFontSize * 7 + swipeView.innerSpacing * 10.5
    property var textInputArea
    property var selectedObj

    property bool defaultSuggestions: false
    property bool dotShortcut: true
    property bool roundedShortcutMenu: true

    onTextInputChanged: {
        console.log("Springboard | text input changed")
        listModel.update()
    }

    Component.onCompleted: {
        listModel.update()
    }

    ListView {
        id: listView
        anchors.fill: parent
        headerPositioning: ListView.OverlayHeader

        header: Column {
            id: header
            width: parent.width
            Label {
                id: headline
                topPadding: swipeView.innerSpacing
                x: swipeView.innerSpacing
                text: qsTr("Springboard")
                font.pointSize: swipeView.headerFontSize
                font.weight: Font.Black
            }
            TextArea {
                padding: swipeView.innerSpacing
                id: textArea
                x: swipeView.innerSpacing
                width: parent.width - swipeView.innerSpacing * 2
                placeholderText: qsTr("Type anything")
                color: Universal.foreground
                placeholderTextColor: "darkgrey"
                font.pointSize: swipeView.largeFontSize
                wrapMode: Text.WordWrap
                leftPadding: 0.0
                rightPadding: swipeView.innerSpacing

                background: Rectangle {
                    color: "black"
                    border.color: "transparent"
                }

                Binding {
                    target: springBoard
                    property: "textInput"
                    value: textArea.text
                }
                Binding {
                    target: springBoard
                    property: "textFocus"
                    value: activeFocus
                }
                Binding {
                    target: springBoard
                    property: "textInputArea"
                    value: textArea
                }

                onActiveFocusChanged: {
                    headline.color = activeFocus ? "grey" : Universal.foreground
                }

                Button {
                    id: deleteButton
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: swipeView.largeFontSize * 2
                    flat: true
                    topPadding: 0.0
                    anchors.top: parent.top
                    anchors.right: parent.right

                    onClicked: {
                        textArea.text = ""
                        textArea.activeFocus = false
                    }
                }
            }
            Rectangle {
                width: parent.width
                border.color: Universal.accent
                color: "transparent"
                height: 1.1
            }
        }

        model: ListModel {
            id: listModel

            function phoneNumberForContact() {
                var phoneNumber = -1
                if (selectedObj) {
                    // Todo: Offer selection
                    if (selectedObj["phone.mobile"].length > 0) {
                        phoneNumber = selectedObj["phone.mobile"]
                    } else if (selectedObj["phone.home"].length > 0) {
                        phoneNumber = selectedObj["phone.home"]
                    } else if (selectedObj["phone.work"].length > 0) {
                        phoneNumber = selectedObj["phone.work"]
                    }
                } else {
                    toast.text = qsTr("Sorry. I couldn't identify the contact")
                    toast.show()
                }

                return phoneNumber
            }

            function emailAddressForContact() {
                var emailAddress
                if (selectedObj) {
                    console.log("Springboard | Contact " + contactIdentifier + " " + contact.name)
                    // Todo: Offer selection
                    if (selectedObj["email.home"].length > 0) {
                        emailAddress = selectedObj["email.home"]
                    } else if (selectedObj["email.work"].length > 0) {
                        emailAddress = selectedObj["email.work"]
                    } else if (selectedObj["email.mobile"].length > 0) {
                        emailAddress = selectedObj["email.mobile"]
                    }
                } else {
                    toast.text = qsTr("Sorry. I couldn't identify the contact")
                    toast.show()
                }

                return emailAddress
            }

            function executeAction(actionValue, actionType, actionObj) {
                console.log(actionValue + ":" + actionType + ":" + actionObj["id"])

                switch (actionType) {
                    case swipeView.actionType.MakeCall:
                        var phoneNumber = textInput
                        if (!textInputStartsWithPhoneNumber()) {
                            phoneNumber = phoneNumberForContact()
                        }
                        console.log("Springboard | Will call " + phoneNumber)
                        Qt.openUrlExternally("tel:" + phoneNumber)
                        textInputArea.text = ""
                        break
                    case swipeView.actionType.SendSMS:
                        var idx = textInput.search(/\s/)
                        console.log("Springboard | Index: " + idx)
                        phoneNumber = textInput.substring(0,idx)
                        var message = textInput.substring(idx+1,textInput.length)
                        if (!textInputStartsWithPhoneNumber()) {
                            phoneNumber = phoneNumberForContact()
                        }
                        if (phoneNumber === -1) {
                            toast.text = qsTr("Sorry. Contact has no mobile phone number")
                            toast.show()
                        } else {
                            console.log("Springboard | Will send message " + message)
                            Qt.openUrlExternally("sms:" + phoneNumber + "?body=" + encodeURIComponent(message))
                        }
                        textInputArea.text = ""
                        break
                    case swipeView.actionType.SendEmail:
                        idx = textInput.search(/\s/)
                        var recipient = textInput.substring(0, idx)
                        console.log("Springboard | 2nd Index: " + idx)
                        console.log("Springboard | Recipient: " + recipient)
                        if (!textInputStartWithEmailAddress()) {
                            recipient = emailAddressForContact()
                        }
                        if (recipient !== null) {
                            message = textInput.substring(idx+1, textInput.length)
                            idx = message.indexOf("\n")
                            if (idx > -1) {
                                var subject = message.substring(0, idx)
                                var body = message.substring(idx+1, message.length)
                                message = "mailto:" + recipient + "?subject=" + encodeURIComponent(subject) + "&body=" + encodeURIComponent(body)
                            } else {
                                body = message.substring(idx+1, message.length)
                                message = "mailto:" + recipient + "?body=" + encodeURIComponent(body)
                            }
                            console.log("Springboard | Will send email " + message)
                            Qt.openUrlExternally(message)
                        } else {
                            toast.text = qsTr("Sorry. Contact has no email address")
                            toast.show()
                        }
                        textInputArea.text = ""
                        break
                    case swipeView.actionType.SearchWeb:
                        message = encodeURIComponent(textInput)
                        console.log("Springboard | Will search for " + message)
                        Qt.openUrlExternally("https://duck.com?q=" + message)
                        textInputArea.text = ""
                        break
                    case swipeView.actionType.OpenURL:
                        console.log("Springboard | Will open in browser" + textInput)
                        if (/^http/.test(textInput)) {
                            Qt.openUrlExternally(textInput)
                        } else {
                            Qt.openUrlExternally("http://" + textInput)
                        }
                        textInputArea.text = ""
                        break
                    case swipeView.actionType.CreateNote:
                        console.log("Springboard | Will create note")
                        // todo create note
                        var source = "note" + Math.floor(Date.now()) + ".txt"
                        myNote.setSource(source)
                        myNote.write(textInput)
                        console.log( "WRITE "+ myNote.write(textInput))
                        console.log("Springboard | READ " + myNote.read())
                        //Qt.openUrlExternally("content:///data/user/0/com.volla.launcher/files/" + source)
                        textInputArea.text = ""
                        break
                    case swipeView.actionType.SuggestContact:
                        console.log("Springboard | Will complete " + textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue)
                        actionValue = "@" + actionValue.replace(/\s/g, "_")
                        textInputArea.text = textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue + " "
                        textInputArea.cursorPosition = textInput.length
                        textInputArea.forceActiveFocus()
                        springBoard.selectedObject = actionObj
                }
            }

            function textInputHasMultiTokens() {
                return /\S+\s\S+/.test(textInput)
            }

            function textInputHasMultiLines() {
                return /\n/.test(textInput)
            }

            function textInputHasContactPrefix() {
                return textInput.indexOf("@") === 0
            }

            function textInputStartsWithPhoneNumber() {
                return /^\+?\d{4,}(\s\S+)?/.test(textInput)
            }

            function textInputStartWithEmailAddress() {
                return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}\s\S+/.test(textInput)
            }

            function textInputIsWebAddress() {
                var urlregex = /^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$/
                return urlregex.test(textInput.trim());
            }

            function update() {
                console.log("Springboard | update model for " + textInput);

                var filteredSuggestionObj = new Array
                var filteredSuggestion
                var suggestion
                var found
                var i

                if (textInputHasMultiTokens()) {
                    if (textInputHasContactPrefix()) {
                        filteredSuggestionObj[0] = [qsTr("Send message"), swipeView.actionType.SendSMS]
                        filteredSuggestionObj[1] = [qsTr("Send email"), swipeView.actionType.SendEmail]
                    } else if (textInputStartsWithPhoneNumber()) {
                        filteredSuggestionObj[0] = [qsTr("Send message"), swipeView.actionType.SendSMS]
                    } else if (textInputStartWithEmailAddress()) {
                        filteredSuggestionObj[0] = [qsTr("Send email"), swipeView.actionType.SendEmail]
                    } else if (textInputHasMultiLines()) {
                        filteredSuggestionObj[0] = [qsTr("Create note"), swipeView.actionType.CreateNote]
                    } else {
                        filteredSuggestionObj[0] = [qsTr("Create note"), swipeView.actionType.CreateNote]
                        filteredSuggestionObj[1] = [qsTr("Search web"), swipeView.actionType.SearchWeb]
                    }
                } else if (textInputHasContactPrefix()) {                   
                    var lastChar = textInput.substring(textInput.length - 1, textInput.length)
                    console.log("Springboard | last char: " + lastChar)
                    if (lastChar === " ") {
                        filteredSuggestionObj[0] = [qsTr("Call"), swipeView.actionType.MakeCall]
                    }

                    var lastToken = textInput.substring(1, textInput.length).toLowerCase()
                    console.log("Springboard | last token:" + lastToken)
                    for (i = 0; i < swipeView.contacts.length; i++) {
                        var contact = swipeView.contacts[i]
                        var name = contact["name"].toLowerCase()
                        if (lastToken.length === 0 || name.includes(lastToken)) {
                            filteredSuggestionObj[i] = [contact["name"], swipeView.actionType.SuggestContact, contact]
                        }
                    }
                } else if (textInputIsWebAddress()) {
                    filteredSuggestionObj[0] = [qsTr("Open in browser"), swipeView.actionType.OpenURL]
                } else if (textInputStartsWithPhoneNumber()) {
                    filteredSuggestionObj[0] = [qsTr("Call"), swipeView.actionType.MakeCall]
                } else if (textInput.length > 1) {
                    filteredSuggestionObj[0] = [qsTr("Search web"), swipeView.actionType.SearchWeb]
                } else if (defaultSuggestions) {
                    filteredSuggestionObj[0] = [qsTr("Make Call"), swipeView.actionType.MakeCall]
                    filteredSuggestionObj[1] = [qsTr("Create Message"), swipeView.actionType.SendSMS]
                    filteredSuggestionObj[2] = [qsTr("Create Mail"), swipeView.actionType.SendEmail]
                    filteredSuggestionObj[3] = [qsTr("Open Cam"), swipeView.actionType.OpenCam]
                    filteredSuggestionObj[4] = [qsTr("Gallery"), swipe.actionType.ShowGallery]
                    filteredSuggestionObj[5] = [qsTr("Recent people"), swipe.actionType.ShowContacts]
                    filteredSuggestionObj[6] = [qsTr("Recent threads"), swipe.actionType.ShowThreads]
                    filteredSuggestionObj[7] = [qsTr("Recent news"), swipe.actionType.ShowNews]
                }

                var existingSuggestionObj = new Object
                for (i = 0; i < count; ++i) {
                    suggestion = get(i).text
                    existingSuggestionObj[suggestion] = true
                }

                // remove items no longer in filtered set
                i = 0
                while (i < count) {
                    suggestion = get(i).text
                    found = filteredSuggestionObj.hasOwnProperty(suggestion)
                    if (!found) {
                        remove(i)
                    } else {
                        i++
                    }
                }

                // add new items
                filteredSuggestionObj.forEach(function (item, index) {
                    found = existingSuggestionObj.hasOwnProperty(item)
                    if (!found) {
                        // for simplicity, just adding to end instead of corresponding position in original list
                        append({ "text": item[0], "action": item[1], "object": item[2] })
                    }
                    console.log("Springboard | Append Suggestion: " + item[0])
                });
            }
        }

        currentIndex: -1 // otherwise currentItem will steal focus

        delegate: Rectangle {
            id: backgroundItem

            height: button.height
            width: parent.width
            color: model.action < 20000 ? "transparent" : Universal.accent
            Button {
                leftPadding: swipeView.innerSpacing
                topPadding: model.index === 0 ? swipeView.innerSpacing : 0
                bottomPadding: model.index === listModel.count - 1 ? swipeView.innerSpacing : swipeView.innerSpacing / 2
                id: button
                anchors.top: parent.top
                text: styledText(model.text, textInput.substring(1, textInput.length))
                font.pointSize: swipeView.largeFontSize
                flat: model.action >= 20000 ? false : true
                background: Rectangle {
                    color: "transparent"
                }

                function styledText(fullText, highlightedText) {
                    if (fullText && highlightedText) {
                        console.log("Springboard | Will highlight '" + highlightedText + "' in '" + fullText + "'")
                        return fullText.replace(highlightedText, "<b>" + highlightedText + "</b>");
                    } else {
                        return fullText;
                    }
                }

                onClicked: {
                    console.log("Springboard | Menu item clicked")
                    listModel.executeAction(model.text, model.action, model.object)
                }
            }
        }

        AN.Toast {
            id: toast
            text: qsTr("Not yet supported")
            longDuration: true
        }

        FileIO {
            id: myNote
            source: "myNote.txt"
            onError: {
                console.log(msg)
            }
        }
    }

    MouseArea {
        id: shortcutMenu
        width: parent.width
        height: dotShortcut ? swipeView.innerSpacing * 4 : swipeView.innerSpacing * 3 // parent.height / 2 // todo: make dynamic
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        preventStealing: true
        enabled: !textInputArea.activeFocus && !defaultSuggestions

        property var selectedMenuItem: rootMenuButton

        onSelectedMenuItemChanged: {
            peopleLabel.font.bold = selectedMenuItem === peopleLabel
            peopleLabel.font.pointSize = selectedMenuItem === peopleLabel ? swipeView.largeFontSize * 1.2 : swipeView.largeFontSize
            threadLabel.font.bold = selectedMenuItem === threadLabel
            threadLabel.font.pointSize = selectedMenuItem === threadLabel ? swipeView.largeFontSize * 1.2 : swipeView.largeFontSize
            newsLabel.font.bold = selectedMenuItem === newsLabel
            newsLabel.font.pointSize = selectedMenuItem === newsLabel ? swipeView.largeFontSize * 1.2 : swipeView.largeFontSize
            galleryLabel.font.bold = selectedMenuItem === galleryLabel
            galleryLabel.font.pointSize = selectedMenuItem === galleryLabel ? swipeView.largeFontSize * 1.2 : swipeView.largeFontSize
            agendaLabel.font.bold = selectedMenuItem === agendaLabel
            agendaLabel.font.pointSize = selectedMenuItem === agendaLabel ? swipeView.largeFontSize * 1.2 : swipeView.largeFontSize
            cameraLabel.font.bold = selectedMenuItem === cameraLabel
            cameraLabel.font.pointSize = selectedMenuItem === cameraLabel ? swipeView.largeFontSize * 1.2 : swipeView.largeFontSize
            dialerLabel.font.bold = selectedMenuItem === dialerLabel
            dialerLabel.font.pointSize = selectedMenuItem === dialerLabel ? swipeView.largeFontSize * 1.2 : swipeView.largeFontSize
        }

        onEntered: {
            console.log("Springboard | entered")
            var rbPoint = mapFromItem(rootMenuButton, 0, 0)
            var touchY = dotShortcut ? rbPoint.y : rbPoint.y - rootMenuButton.height
            var touchHeight = dotShortcut ? rootMenuButton.height : rootMenuButton.height * 2
            if (mouseX > rbPoint.x && mouseX < rbPoint.x + rootMenuButton.width
                    && mouseY > touchY && mouseY < touchY + touchHeight) {
                console.log("Springboard | enable menu")
                //shortcutBackground.visible = true
                shortcutMenu.height = springBoard.height * 0.6
                shortcutBackground.width = roundedShortcutMenu ? parent.width - swipeView.innerSpacing * 4 : parent.width
                shortcutBackground.height = shortcutColumn.height
                shortcutColumn.opacity = 1
            }
        }

        onExited: {
            console.log("Springboard | exited")
            //shortcutBackground.visible = false
            shortcutBackground.width = dotShortcut ? swipeView.innerSpacing * 2 : parent.width
            shortcutBackground.height = dotShortcut ? swipeView.innerSpacing * 2 : swipeView.innerSpacing
            shortcutColumn.opacity = 0
            shortcutMenu.executeSelection()
            selectedMenuItem = rootMenuButton
            shortcutMenu.height = dotShortcut ? swipeView.innerSpacing * 4 : swipeView.innerSpacing * 3
        }

        onCanceled: {
            console.log("Springboard | cancelled")
            //shortcutBackground.visible = false
            shortcutBackground.width = dotShortcut ? swipeView.innerSpacing * 2 : parent.width
            shortcutBackground.height = dotShortcut ? swipeView.innerSpacing * 2 : swipeView.innerSpacing
            shortcutColumn.opacity = 0
            shortcutMenu.executeSelection()
            selectedMenuItem = rootMenuButton
            shortcutMenu.height = dotShortcut ? swipeView.innerSpacing * 4 : swipeView.innerSpacing * 3
        }

        onPositionChanged: {
            var plPoint = mapFromItem(peopleLabel, 0, 0)
            var tlPoint = mapFromItem(threadLabel, 0, 0)
            var nlPoint = mapFromItem(newsLabel, 0, 0)
            var glPoint = mapFromItem(galleryLabel, 0, 0)
            var alPoint = mapFromItem(agendaLabel, 0, 0)
            var clPoint = mapFromItem(cameraLabel, 0, 0)
            var dlPoint = mapFromItem(dialerLabel, 0, 0)

            if (mouseY > plPoint.y && mouseY < plPoint.y + peopleLabel.height) {
                selectedMenuItem = peopleLabel
            } else if (mouseY > tlPoint.y && mouseY < tlPoint.y + threadLabel.height) {
                selectedMenuItem = threadLabel
            } else if (mouseY > nlPoint.y && mouseY < nlPoint.y + newsLabel.height) {
                selectedMenuItem = newsLabel
            } else if (mouseY > glPoint.y && mouseY < glPoint.y + galleryLabel.height) {
                selectedMenuItem = galleryLabel
            } else if (mouseY > alPoint.y && mouseY < alPoint.y + agendaLabel.height) {
                selectedMenuItem = agendaLabel
            } else if (mouseY > clPoint.y && mouseY < clPoint.y + cameraLabel.height) {
                selectedMenuItem = cameraLabel
            } else if (mouseY > dlPoint.y && mouseY < dlPoint.y + dialerLabel.height) {
                selectedMenuItem = dialerLabel
            } else {
                selectedMenuItem = rootMenuButton
            }
        }

        function executeSelection() {
            if (shortcutColumn.opacity === 0.0) {
                return;
            }

            var collectionPage = Qt.createComponent("/Collections.qml", springBoard)

            if (selectedMenuItem == peopleLabel) {
                console.log("Springboard | Show people")
                swipeView.updateCollectionMode(swipeView.collectionMode.People)
            } else if (selectedMenuItem == threadLabel) {
                console.log("Springboard | Show threads")
                swipeView.updateCollectionMode(swipeView.collectionMode.Threads)
            } else if (selectedMenuItem == newsLabel) {
                console.log("Springboard | Show news")
                swipeView.updateCollectionMode(swipeView.collectionMode.News)
            } else if (selectedMenuItem == galleryLabel) {
                console.log("Springboard | Show gallery")
                backEnd.runApp(swipeView.galleryApp)
            } else if (selectedMenuItem == agendaLabel) {
                console.log("Springboard | Show agenda")
                backEnd.runApp(swipeView.calendarApp)
            } else if (selectedMenuItem == cameraLabel) {
                console.log("Springboard | Show camera")
                backEnd.runApp(swipeView.cameraApp)
            } else if (selectedMenuItem == dialerLabel) {
                console.log("Springboard | Show dialer")
                backEnd.runApp(swipeView.phoneApp)
            }
        }

        BackEnd {
            id: backEnd
        }

        Rectangle {
            id: shortcutBackground
            anchors.bottom: parent.bottom
            anchors.bottomMargin: roundedShortcutMenu ? swipeView.innerSpacing * 2 : 0
            //anchors.horizontalCenter: parent.horizontalCenter
            anchors.right: parent.right
            anchors.rightMargin: roundedShortcutMenu ? swipeView.innerSpacing * 2 : 0
            //implicitHeight: shortcutColumn.height
            //width: dotShortcut ? swipeView.innerSpacing * 2 : parent.width
            height: dotShortcut ? swipeView.innerSpacing * 2 : swipeView.innerSpacing
            width: dotShortcut ? swipeView.innerSpacing * 2 : parent.width
            color: Universal.accent
            visible: true
            radius: roundedShortcutMenu ? rootMenuButton.width / 2 : 0

            property int duration: 150

            Behavior on width {
                NumberAnimation {
                    duration: shortcutBackground.duration
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: shortcutBackground.duration
                }
            }
        }

        Column {
            id: shortcutColumn
            visible: true // shortcutBackground.visible
            opacity: 0.0
            width: parent.width
            height: menuheight
            anchors.bottom: parent.bottom
            anchors.bottomMargin: roundedShortcutMenu ? swipeView.innerSpacing * 2 : 0

            property int duration: 200
            property real leftDistance: parent.width / 4

            Label {
                id: dialerLabel
                text: qsTr("Show Dialer")
                font.pointSize: swipeView.largeFontSize
                anchors.left: parent.left
                topPadding: swipeView.innerSpacing * 1.5
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: swipeView.innerSpacing
            }
            Label {
                id: cameraLabel
                text: qsTr("Open Camera")
                font.pointSize: swipeView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: swipeView.innerSpacing
            }
            Label {
                id: agendaLabel
                text: qsTr("Agenda")
                font.pointSize: swipeView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: swipeView.innerSpacing
            }
            Label {
                id: galleryLabel
                text: qsTr("Gallery")
                font.pointSize: swipeView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: swipeView.innerSpacing
            }
            Label {
                id: newsLabel
                text: qsTr("Recent News")
                font.pointSize: swipeView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: swipeView.innerSpacing
            }
            Label {
                id: threadLabel
                text: qsTr("Recent Threads")
                font.pointSize: swipeView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: swipeView.innerSpacing
            }
            Label {
                id: peopleLabel
                text: qsTr("Recent People")
                font.pointSize: swipeView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: swipeView.innerSpacing * 2
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: shortcutColumn.duration
                }
            }
        }

        Rectangle {
            id: rootMenuButton
            visible: true
            height: dotShortcut ? swipeView.innerSpacing * 2 : swipeView.innerSpacing
            width: dotShortcut ? swipeView.innerSpacing * 2 : parent.width
            color: Universal.accent
            radius: dotShortcut ? width * 0.5 : 0.0
            anchors.right: parent.right
            anchors.rightMargin: dotShortcut ? swipeView.innerSpacing * 2 : 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dotShortcut ? swipeView.innerSpacing * 2 : 0
        }
    }
}
