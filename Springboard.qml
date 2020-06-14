import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import FileIO 1.0
import com.volla.launcher.backend 1.0
import AndroidNative 1.0 as AN

Page {
    id: springBoard
    anchors.fill: parent
    topPadding: mainView.innerSpacing

    property string textInput
    property bool textFocus
    property real menuheight: mainView.largeFontSize * 7 + mainView.innerSpacing * 10.5
    property var textInputArea
    property var selectedObj

    property bool defaultSuggestions: false
    property bool dotShortcut: true
    property bool roundedShortcutMenu: true

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

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
                topPadding: mainView.innerSpacing
                x: mainView.innerSpacing
                text: qsTr("Springboard")
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
                color: mainView.fontColor
            }
            TextArea {
                padding: mainView.innerSpacing
                id: textArea
                x: mainView.innerSpacing
                width: parent.width - mainView.innerSpacing * 2
                placeholderText: qsTr("Type anything")
                color: mainView.fontColor
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.largeFontSize
                wrapMode: Text.WordWrap
                leftPadding: 0.0
                rightPadding: mainView.innerSpacing

                background: Rectangle {
                    color: "transparent"
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
                    headline.color = textArea.activeFocus ? "grey" : mainView.fontColor
                }

                Button {
                    id: deleteButton
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: mainView.largeFontSize * 2
                    flat: true
                    topPadding: 0.0
                    anchors.top: parent.top
                    anchors.right: parent.right

                    onClicked: {
                        textArea.text = ""
                        textArea.focus = false
                    }
                }
            }
            Rectangle {
                width: parent.width
                border.color: "transparent"
                color: "transparent"
                height: 1.1
            }
        }

        model: ListModel {
            id: listModel

            function phoneNumberForContact() {
                var phoneNumber = -1
                if (selectedObj !== undefined) {
                    // Todo: Offer selection
                    if (selectedObj["phone.mobile"].length > 0) {
                        phoneNumber = selectedObj["phone.mobile"]
                    } else if (selectedObj["phone.home"].length > 0) {
                        phoneNumber = selectedObj["phone.home"]
                    } else if (selectedObj["phone.work"].length > 0) {
                        phoneNumber = selectedObj["phone.work"]
                    }
                } else {
                    mainView.showToast(qsTr("Sorry. I couldn't identify the contact"))
                }

                return phoneNumber
            }

            function emailAddressForContact() {
                var emailAddress
                if (selectedObj) {
                    console.log("Springboard | Contact " + selectedObj["id"] + " " + selectedObj["name"])
                    // Todo: Offer selection
                    if (selectedObj["email.home"].length > 0) {
                        emailAddress = selectedObj["email.home"]
                    } else if (selectedObj["email.work"].length > 0) {
                        emailAddress = selectedObj["email.work"]
                    } else if (selectedObj["email.mobile"].length > 0) {
                        emailAddress = selectedObj["email.mobile"]
                    }
                } else {
                    mainView.showToast(qsTr("Sorry. I couldn't identify the contact"))
                }

                return emailAddress
            }

            function executeAction(actionValue, actionType, actionObj) {
                if (actionObj !== undefined) {
                    console.log(actionValue + ":" + actionType + ":" + actionObj["id"])
                } else {
                    console.log(actionValue + ":" + actionType)
                }

                switch (actionType) {
                    case mainView.actionType.MakeCall:
                        var phoneNumber = textInput
                        if (!textInputStartsWithPhoneNumber()) {
                            phoneNumber = phoneNumberForContact()
                        }
                        console.log("Springboard | Will call " + phoneNumber)
                        Qt.openUrlExternally("tel:" + phoneNumber)
                        textInputArea.text = ""
                        break
                    case mainView.actionType.SendSMS:
                        var idx = textInput.search(/\s/)
                        console.log("Springboard | Index: " + idx)
                        phoneNumber = textInput.substring(0,idx)
                        var message = textInput.substring(idx+1,textInput.length)
                        if (!textInputStartsWithPhoneNumber()) {
                            phoneNumber = phoneNumberForContact()
                        }
                        if (phoneNumber === -1) {
                            mainView.showToast(qsTr("Sorry. Contact has no mobile phone number"))
                        } else {
                            console.log("Springboard | Will send message " + message)
                            Qt.openUrlExternally("sms:" + phoneNumber + "?body=" + encodeURIComponent(message))
                        }
                        textInputArea.text = ""
                        break
                    case mainView.actionType.SendEmail:
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
                            mainView.showToast(qsTr("Sorry. Contact has no email address"))
                        }
                        textInputArea.text = ""
                        break
                    case mainView.actionType.SearchWeb:
                        message = encodeURIComponent(textInput)
                        console.log("Springboard | Will search for " + message)
                        Qt.openUrlExternally("https://duck.com?q=" + message)
                        textInputArea.text = ""
                        break
                    case mainView.actionType.OpenURL:
                        console.log("Springboard | Will open in browser " + textInput)
                        if (/^http/.test(textInput)) {
                            var url = textInput.trim()
                        } else {
                            url = "https://" + textInput.trim()

                        }
                        var success = Qt.openUrlExternally(url)
                        console.log("Springboard | Did open in browser: " + success)
                        textInputArea.text = ""
                        break
                    case mainView.actionType.CreateNote:
                        console.log("Springboard | Will create note")
                        // todo create note
                        var source = "note" + Math.floor(Date.now()) + ".txt"
                        myNote.setSource(source)
                        myNote.write(textInput)
                        console.log( "Springboard | WRITE "+ myNote.write(textInput))
                        console.log("Springboard | READ " + myNote.read())
                        // Qt.openUrlExternally("content:///storage/emulated/0/Documents/" + source)
                        textInputArea.text = ""
                        break
                    case mainView.actionType.SuggestContact:
                        console.log("Springboard | Will complete " + textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue)
                        actionValue = "@" + actionValue.replace(/\s/g, "_")
                        textInputArea.text = textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue + " "
                        textInputArea.cursorPosition = textInput.length
                        textInputArea.forceActiveFocus()
                        springBoard.selectedObj = actionObj
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
                        filteredSuggestionObj[0] = [qsTr("Send message"), mainView.actionType.SendSMS]
                        filteredSuggestionObj[1] = [qsTr("Send email"), mainView.actionType.SendEmail]
                    } else if (textInputStartsWithPhoneNumber()) {
                        filteredSuggestionObj[0] = [qsTr("Send message"), mainView.actionType.SendSMS]
                    } else if (textInputStartWithEmailAddress()) {
                        filteredSuggestionObj[0] = [qsTr("Send email"), mainView.actionType.SendEmail]
                    } else if (textInputHasMultiLines()) {
                        filteredSuggestionObj[0] = [qsTr("Create note"), mainView.actionType.CreateNote]
                    } else {
                        filteredSuggestionObj[0] = [qsTr("Create note"), mainView.actionType.CreateNote]
                        filteredSuggestionObj[1] = [qsTr("Search web"), mainView.actionType.SearchWeb]
                    }
                } else if (textInputHasContactPrefix()) {                   
                    var lastChar = textInput.substring(textInput.length - 1, textInput.length)
                    console.log("Springboard | last char: " + lastChar)
                    if (lastChar === " ") {
                        filteredSuggestionObj[0] = [qsTr("Call"), mainView.actionType.MakeCall]
                    }

                    var lastToken = textInput.substring(1, textInput.length).toLowerCase()
                    console.log("Springboard | last token:" + lastToken)
                    for (i = 0; i < mainView.contacts.length; i++) {
                        var contact = mainView.contacts[i]
                        var name = contact["name"].toLowerCase()
                        if (lastToken.length === 0 || name.includes(lastToken)) {
                            filteredSuggestionObj[i] = [contact["name"], mainView.actionType.SuggestContact, contact]
                        }
                    }
                } else if (textInputIsWebAddress()) {
                    filteredSuggestionObj[0] = [qsTr("Open in browser"), mainView.actionType.OpenURL]
                } else if (textInputStartsWithPhoneNumber()) {
                    filteredSuggestionObj[0] = [qsTr("Call"), mainView.actionType.MakeCall]
                } else if (textInput.length > 1) {
                    filteredSuggestionObj[0] = [qsTr("Search web"), mainView.actionType.SearchWeb]
                } else if (defaultSuggestions) {
                    filteredSuggestionObj[0] = [qsTr("Make Call"), mainView.actionType.MakeCall]
                    filteredSuggestionObj[1] = [qsTr("Create Message"), mainView.actionType.SendSMS]
                    filteredSuggestionObj[2] = [qsTr("Create Mail"), mainView.actionType.SendEmail]
                    filteredSuggestionObj[3] = [qsTr("Open Cam"), mainView.actionType.OpenCam]
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
                id: button
                leftPadding: mainView.innerSpacing
                topPadding: model.index === 0 ? mainView.innerSpacing : 0
                bottomPadding: model.index === listModel.count - 1 ? mainView.innerSpacing : mainView.innerSpacing / 2
                anchors.top: parent.top
                text: styledText(model.text, textInput.substring(1, textInput.length))
                flat: model.action >= 20000 ? false : true
                contentItem: Text {
                    text: button.text
                    font.pointSize: mainView.largeFontSize
                    color: model.action < 20000 ? Universal.foreground : "white"
                }
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
        height: dotShortcut ? mainView.innerSpacing * 4 : mainView.innerSpacing * 3 // parent.height / 2 // todo: make dynamic
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        preventStealing: true
        enabled: !textInputArea.activeFocus && !defaultSuggestions

        property var selectedMenuItem: rootMenuButton

        onSelectedMenuItemChanged: {
            peopleLabel.font.bold = selectedMenuItem === peopleLabel
            peopleLabel.font.pointSize = selectedMenuItem === peopleLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            threadLabel.font.bold = selectedMenuItem === threadLabel
            threadLabel.font.pointSize = selectedMenuItem === threadLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            newsLabel.font.bold = selectedMenuItem === newsLabel
            newsLabel.font.pointSize = selectedMenuItem === newsLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            galleryLabel.font.bold = selectedMenuItem === galleryLabel
            galleryLabel.font.pointSize = selectedMenuItem === galleryLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            agendaLabel.font.bold = selectedMenuItem === agendaLabel
            agendaLabel.font.pointSize = selectedMenuItem === agendaLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            cameraLabel.font.bold = selectedMenuItem === cameraLabel
            cameraLabel.font.pointSize = selectedMenuItem === cameraLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            dialerLabel.font.bold = selectedMenuItem === dialerLabel
            dialerLabel.font.pointSize = selectedMenuItem === dialerLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
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
                shortcutBackground.width = roundedShortcutMenu ? parent.width - mainView.innerSpacing * 4 : parent.width
                shortcutBackground.height = shortcutColumn.height
                shortcutColumn.opacity = 1
            }
        }

        onExited: {
            console.log("Springboard | exited")
            //shortcutBackground.visible = false
            shortcutBackground.width = dotShortcut ? mainView.innerSpacing * 2 : parent.width
            shortcutBackground.height = dotShortcut ? mainView.innerSpacing * 2 : mainView.innerSpacing
            shortcutColumn.opacity = 0
            shortcutMenu.executeSelection()
            selectedMenuItem = rootMenuButton
            shortcutMenu.height = dotShortcut ? mainView.innerSpacing * 4 : mainView.innerSpacing * 3
        }

        onCanceled: {
            console.log("Springboard | cancelled")
            //shortcutBackground.visible = false
            shortcutBackground.width = dotShortcut ? mainView.innerSpacing * 2 : parent.width
            shortcutBackground.height = dotShortcut ? mainView.innerSpacing * 2 : mainView.innerSpacing
            shortcutColumn.opacity = 0
            shortcutMenu.executeSelection()
            selectedMenuItem = rootMenuButton
            shortcutMenu.height = dotShortcut ? mainView.innerSpacing * 4 : mainView.innerSpacing * 3
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
                mainView.updateCollectionPage(mainView.collectionMode.People)
            } else if (selectedMenuItem == threadLabel) {
                console.log("Springboard | Show threads")
                mainView.updateCollectionPage(mainView.collectionMode.Threads)
            } else if (selectedMenuItem == newsLabel) {
                console.log("Springboard | Show news")
                mainView.updateCollectionPage(mainView.collectionMode.News)
            } else if (selectedMenuItem == galleryLabel) {
                console.log("Springboard | Show gallery")
                backEnd.runApp(mainView.galleryApp)
            } else if (selectedMenuItem == agendaLabel) {
                console.log("Springboard | Show agenda")
                backEnd.runApp(mainView.calendarApp)
            } else if (selectedMenuItem == cameraLabel) {
                console.log("Springboard | Show camera")
                backEnd.runApp(mainView.cameraApp)
            } else if (selectedMenuItem == dialerLabel) {
                console.log("Springboard | Show dialer")
                backEnd.runApp(mainView.phoneApp)
            }
        }

        BackEnd {
            id: backEnd
        }

        Rectangle {
            id: shortcutBackground
            anchors.bottom: parent.bottom
            anchors.bottomMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0
            //anchors.horizontalCenter: parent.horizontalCenter
            anchors.right: parent.right
            anchors.rightMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0
            //implicitHeight: shortcutColumn.height
            //width: dotShortcut ? mainView.innerSpacing * 2 : parent.width
            height: dotShortcut ? mainView.innerSpacing * 2 : mainView.innerSpacing
            width: dotShortcut ? mainView.innerSpacing * 2 : parent.width
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
            anchors.bottomMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0

            property int duration: 200
            property real leftDistance: parent.width / 4

            Label {
                id: dialerLabel
                text: qsTr("Show Dialer")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                topPadding: mainView.innerSpacing * 1.5
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: cameraLabel
                text: qsTr("Open Camera")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: agendaLabel
                text: qsTr("Agenda")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: galleryLabel
                text: qsTr("Gallery")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: newsLabel
                text: qsTr("Recent News")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: threadLabel
                text: qsTr("Recent Threads")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: peopleLabel
                text: qsTr("Recent People")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing * 2
                color: "white"
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
            height: dotShortcut ? mainView.innerSpacing * 2 : mainView.innerSpacing
            width: dotShortcut ? mainView.innerSpacing * 2 : parent.width
            color: Universal.accent
            radius: dotShortcut ? width * 0.5 : 0.0
            anchors.right: parent.right
            anchors.rightMargin: dotShortcut ? mainView.innerSpacing * 2 : 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dotShortcut ? mainView.innerSpacing * 2 : 0
        }
    }
}
