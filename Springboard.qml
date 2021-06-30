import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import FileIO 1.0
import AndroidNative 1.0 as AN

Page {
    id: springBoard
    anchors.fill: parent
    //topPadding: mainView.innerSpacing

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
        shortcutMenu.updateShortcuts(mainView.getActions())
    }

    function updateShortcuts(actions) {
        shortcutMenu.updateShortcuts(actions)
    }

    ListView {
        id: listView
        anchors.fill: parent
        headerPositioning: mainView.backgroundOpacity === 1.0 ? ListView.OverlayHeader : ListView.InlineHeader

        header: Column {
            id: header
            width: parent.width
            z: 2

            Label {
                id: headline
                topPadding: mainView.innerSpacing * 2
                x: mainView.innerSpacing
                text: qsTr("Springboard")
                width: parent.width
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black

                background: Rectangle {
                    color:  mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
                    border.color: "transparent"
                }
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
                    color:  mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
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
                    visible: textArea.preeditText !== "" || textArea.text !== ""

                    onClicked: {
                        textArea.text = ""
                        textArea.focus = false
                    }
                }
            }
            Rectangle {
                width: parent.width
                color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                border.color: "transparent"
                height: 1.1
            }
        }

        model: ListModel {
            id: listModel

            function checkContacts(contact) {
                var fullName = contact["name"].replace(/\s/g, "_")
                return textInput.indexOf(fullName) == 1
            }

            function validateSelectedObject() {
                if (selectedObj === undefined) {
                    console.log("Try to guess contact")
                    var i = textInput.indexOf(" ")
                    var contacts = mainView.contacts.filter(checkContacts)

                    if (contacts.length === 1) {
                        console.log("Found contact")
                        selectedObj = contacts[0]
                    }
                }
            }

            function phoneNumberForContact() {
                validateSelectedObject()
                var phoneNumber = -1

                if (selectedObj !== undefined) {
                    // todo: offer selection of phone numbers
                    if (selectedObj["phone.mobile"] !== undefined && selectedObj["phone.mobile"].length > 0) {
                        phoneNumber = selectedObj["phone.mobile"]
                    } else if (selectedObj["phone.home"] !== undefined && selectedObj["phone.home"].length > 0) {
                        phoneNumber = selectedObj["phone.home"]
                    } else if (selectedObj["phone.work"] !== undefined && selectedObj["phone.work"].length > 0) {
                        phoneNumber = selectedObj["phone.work"]
                    } else if (selectedObj["phone.other"] !== undefined && selectedObj["phone.other"].length > 0) {
                        phoneNumber = selectedObj["phone.other"]
                    } else {
                        mainView.showToast(qsTr("Sorry. I couldn't find a phone number for this contact"))
                    }
                } else {
                    mainView.showToast(qsTr("Sorry. I couldn't identify the contact"))
                }

                return phoneNumber
            }

            function emailAddressForContact() {
                validateSelectedObject()
                var emailAddress
                if (selectedObj) {
                    console.log("Springboard | Contact " + selectedObj["id"] + " " + selectedObj["name"])
                    // todo: offer selection of email address
                    if (selectedObj["email.home"] !== undefined && selectedObj["email.home"].length > 0) {
                        emailAddress = selectedObj["email.home"]
                    } else if (selectedObj["email.work"] !== undefined && selectedObj["email.work"].length > 0) {
                        emailAddress = selectedObj["email.work"]
                    } else if (selectedObj["email.mobile"] !== undefined && selectedObj["email.mobile"].length > 0) {
                        emailAddress = selectedObj["email.mobile"]
                    } else if (selectedObj["email.other"] !== undefined && selectedObj["email.other"].length > 0) {
                        emailAddress = selectedObj["email.other"]
                    }
                } else {
                    mainView.showToast(qsTr("Sorry. I couldn't identify the contact"))
                }

                return emailAddress
            }

            function parseAndSendEmail(recipient) {
                var idx = textInput.search(/\s/)
                var message = textInput.substring(idx+1, textInput.length).trim()
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
                textInputArea.text = ""
            }

            function textInputStartsWithPhoneNumber() {
                return /^\+?\d{4,}(\s\S+)?/.test(textInput)
            }

            function textInputStartWithEmailAddress() {
                return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}\s\S+/.test(textInput)
            }

            function executeAction(actionValue, actionType, actionObj) {
                if (actionObj !== undefined) {
                    console.log("SpringBoard | " + actionValue + ": " + actionType + ": " + actionObj["id"])
                } else {
                    console.log("SpringBoard | " + actionValue + ": " + actionType)
                }

                switch (actionType) {
                    case mainView.actionType.MakeCall:
                        var phoneNumber = textInput
                        if (!textInputStartsWithPhoneNumber()) {
                            phoneNumber = phoneNumberForContact()
                        }
                        console.log("Springboard | Will call " + phoneNumber)
                        util.makeCall({"number": phoneNumber, "intent": "call"})
                        textInputArea.text = ""
                        break
                    case mainView.actionType.MakeCallToMobile:
                        if (selectedObj !== undefined) {
                            phoneNumber = selectedObj["phone.mobile"]
                            util.makeCall({"number": phoneNumber, "intent": "call"})
                            textInputArea.text = ""
                        } else {
                            mainView.showToast(qsTr("Sorry, no contact was selected"))
                        }
                        break
                    case mainView.actionType.MakeCallToHome:
                        if (selectedObj !== undefined) {
                            phoneNumber = selectedObj["phone.home"]
                            util.makeCall({"number": phoneNumber, "intent": "call"})
                            textInputArea.text = ""
                        } else {
                            mainView.showToast(qsTr("Sorry, no contact was selected"))
                        }
                        break
                    case mainView.actionType.MakeCallToWork:
                        if (selectedObj !== undefined) {
                            phoneNumber = selectedObj["phone.work"]
                            util.makeCall({"number": phoneNumber, "intent": "call"})
                            textInputArea.text = ""
                        } else {
                            mainView.showToast(qsTr("Sorry, no contact was selected"))
                        }
                        break
                    case mainView.actionType.MakeCallToOther:
                        if (selectedObj !== undefined) {
                            phoneNumber = selectedObj["phone.other"]
                            util.makeCall({"number": phoneNumber, "intent": "call"})
                            textInputArea.text = ""
                        } else {
                            mainView.showToast(qsTr("Sorry, no contact was selected"))
                        }
                        break
                    case mainView.actionType.SendSMS:
                        var idx = textInput.search(/\s/)
                        console.log("Springboard | Index: " + idx)
                        phoneNumber = textInput.substring(0,idx)
                        var message = textInput.substring(idx+1,textInput.length)
                        if (!textInputStartsWithPhoneNumber()) {
                            if (selectedObj !== undefined) {
                                phoneNumber = selectedObj["phone.mobile"]
                            } else {
                                mainView.showToast(qsTr("Sorry, no contact was selected"))
                                break
                            }
                        }
                        if (phoneNumber === -1) {
                            mainView.showToast(qsTr("Sorry, the mobile phone number is unknown"))
                        } else {
                            console.log("Springboard | Will send message " + message)
                            AN.SystemDispatcher.dispatch("volla.launcher.messageAction", {"number": phoneNumber, "text": message})
                        }
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
                            parseAndSendEmail(recipient)
                        } else {
                            mainView.showToast(qsTr("Sorry. Contact has no email address"))
                        }
                        break
                    case mainView.actionType.SendEmailToHome:
                        if (selectedObj !== undefined) {
                           parseAndSendEmail(selectedObj["email.home"])
                        } else {
                           mainView.showToast(qsTr("Sorry, no contact was selected"))
                        }
                        break
                    case mainView.actionType.SendEmailToWorl:
                        if (selectedObj !== undefined) {
                           parseAndSendEmail(selectedObj["email.work"])
                        } else {
                           mainView.showToast(qsTr("Sorry, no contact was selected"))
                        }
                        break
                    case mainView.actionType.SendEmailToOther:
                        if (selectedObj !== undefined) {
                           parseAndSendEmail(selectedObj["email.other"])
                        } else {
                           mainView.showToast(qsTr("Sorry, no contact was selected"))
                        }
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
                    case mainView.actionType.AddFeed:
                        var feedUrl = textInput.trim()
                        if (!textInput.startsWith("http")) {
                            feedUrl = "https://" + feedUrl
                        }
                        textInputArea.text = ""
                        mainView.checkAndAddFeed(feedUrl)
                        break
                    case mainView.actionType.CreateNote:
                        console.log("Springboard | Will create note")
                        // todo: create note
                        var source = "note" + Math.floor(Date.now()) + ".txt"
                        myNote.setSource(source)
                        if (myNote.write(textInput)) {
                            mainView.showToast(qsTr("Your note was successfully stored"))
                        }
                        console.log( "Springboard | WRITE "+ myNote.write(textInput))
                        // console.log("Springboard | READ " + myNote.read())
                        // Qt.openUrlExternally("content:///storage/emulated/0/Documents/" + source)
                        textInputArea.text = ""
                        break
                    case mainView.actionType.SuggestContact:
                        console.log("Springboard | Will complete " + textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue)
                        selectedObj = Object.assign({}, actionObj)
                        actionValue = "@" + actionValue.replace(/\s/g, "_")
                        textInputArea.text = textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue + " "
                        textInputArea.cursorPosition = textInput.length
                        textInputArea.forceActiveFocus()
                }
            }

            function update() {
                console.log("Springboard | update model for " + textInput);

                if (textInput.length < 1) {
                    listModel.clear()
                } else if (!springBoardWorker.isRunning) {
                    springBoardWorker.sendMessage({
                        'selectedObj': selectedObj, 'textInput': textInput,
                        'contacts': mainView.contacts, 'model': listModel, 'actionType': mainView.actionType,
                        'actionName': mainView.actionName
                    })
                }
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
                width: parent.width - mainView.innerSpacing
                leftPadding: mainView.innerSpacing
                topPadding: model.index === 0 ? mainView.innerSpacing : 0
                bottomPadding: model.index === listModel.count - 1 ? mainView.innerSpacing : mainView.innerSpacing / 2
                anchors.top: parent.top
                text: styledText(model.text, textInput.substring(1, textInput.length))
                flat: model.action >= 20000 ? false : true
                contentItem: Text {
                    text: button.text
                    elide: Text.ElideRight
                    font.pointSize: mainView.largeFontSize
                    color: model.action < 20000 ? Universal.foreground : "white"
                }
                background: Rectangle {
                    color: "transparent"
                }

                function styledText(fullText, highlightedText) {
                    if (fullText && highlightedText) {
                        console.log("Springboard | Will highlight '" + highlightedText + "' in '" + fullText + "'")
                        highlightedText = highlightedText.charAt(0).toUpperCase() + highlightedText.slice(1)
                        return fullText.replace(highlightedText, "<b>" + highlightedText + "</b>")
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
                mainView.showToast(msg)
            }
        }

        // @disable-check M300
        AN.Util {
            id: util
        }

        Connections {
            target: AN.SystemDispatcher
            onDispatched: {
                if (type === "volla.launcher.messageResponse") {
                    console.log("Springboard | onDispatched: " + type)
                    if (message["sent"]) {
                        textInputArea.text = ""
                    }
                }
            }
        }

        WorkerScript {
            id: springBoardWorker
            source: "scripts/springboard.mjs"
            property var isRunning: false
            onMessage: {
                console.log("Springboard | Message received")
                isRunning = false
            }
        }
    }

    MouseArea {
        id: shortcutMenu
        width: parent.width
        // todo: make dynamic bullet size
        height: dotShortcut ? mainView.innerSpacing * 4 : mainView.innerSpacing * 3
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
            eventLabel.font.bold = selectedMenuItem === eventLabel
            eventLabel.font.pointSize = selectedMenuItem === eventLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            notesLabel.font.bold = selectedMenuItem === notesLabel
            notesLabel.font.pointSize = selectedMenuItem === notesLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize

            if (selectedMenuItem !== rootMenuButton) {
                AN.SystemDispatcher.dispatch("volla.launcher.vibrationAction", {})
            }
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
                shortcutMenu.height = shortcutColumn.height + mainView.innerSpacing * 1.5
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
            //shortcutMenu.executeSelection()
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
            var elPoint = mapFromItem(eventLabel, 0, 0)
            var olPoint = mapFromItem(notesLabel, 0, 0)

            if (peopleLabel.visible && mouseY > plPoint.y && mouseY < plPoint.y + peopleLabel.height) {
                selectedMenuItem = peopleLabel
            } else if (threadLabel.visible && mouseY > tlPoint.y && mouseY < tlPoint.y + threadLabel.height) {
                selectedMenuItem = threadLabel
            } else if (newsLabel.visible && mouseY > nlPoint.y && mouseY < nlPoint.y + newsLabel.height) {
                selectedMenuItem = newsLabel
            } else if (galleryLabel.visible && mouseY > glPoint.y && mouseY < glPoint.y + galleryLabel.height) {
                selectedMenuItem = galleryLabel
            } else if (agendaLabel.visible && mouseY > alPoint.y && mouseY < alPoint.y + agendaLabel.height) {
                selectedMenuItem = agendaLabel
            } else if (cameraLabel.visible && mouseY > clPoint.y && mouseY < clPoint.y + cameraLabel.height) {
                selectedMenuItem = cameraLabel
            } else if (dialerLabel.visible && mouseY > dlPoint.y && mouseY < dlPoint.y + dialerLabel.height) {
                selectedMenuItem = dialerLabel
            } else if (eventLabel.visible && mouseY > elPoint.y && mouseY < elPoint.y + eventLabel.height) {
                selectedMenuItem = eventLabel
            } else if (notesLabel.visible && mouseY > olPoint.y && mouseY < olPoint.y + notesLabel.height) {
                selectedMenuItem = notesLabel
            } else {
                selectedMenuItem = rootMenuButton
            }
        }        

        function updateShortcuts(actions) {
            actions.forEach(function (action, index) {
                switch (action.id) {
                    case mainView.actionType.OpenCam:
                        cameraLabel.visible = action.activated
                        break
                    case mainView.actionType.ShowCalendar:
                        agendaLabel.visible = action.activated
                        break
                    case mainView.actionType.ShowGallery:
                        galleryLabel.visible = action.activated
                        break
                    case mainView.actionType.ShowNotes:
                        notesLabel.visible = action.activated
                        break
                    case mainView.actionType.CreateEvent:
                        eventLabel.visible = action.activated
                        break
                    case mainView.actionType.ShowContacts:
                        peopleLabel.visible = action.activated
                        break
                    case mainView.actionType.ShowThreads:
                        threadLabel.visible = action.activated
                        break
                    case mainView.actionType.ShowNews:
                        newsLabel.visible = action.activated
                        break
                }
            })
        }

        function executeSelection() {
            if (shortcutColumn.opacity === 0.0) {
                return;
            }

            if (selectedMenuItem == peopleLabel) {
                console.log("Springboard | Show people")
                var collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                mainView.updateCollectionPage(mainView.collectionMode.People)
            } else if (selectedMenuItem == threadLabel) {
                console.log("Springboard | Show threads")
                collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                mainView.updateCollectionPage(mainView.collectionMode.Threads)
            } else if (selectedMenuItem == newsLabel) {
                console.log("Springboard | Show news")
                collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                mainView.updateCollectionPage(mainView.collectionMode.News)
            } else if (selectedMenuItem == galleryLabel) {
                console.log("Springboard | Show gallery")
                AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": mainView.galleryApp})
            } else if (selectedMenuItem == agendaLabel) {
                console.log("Springboard | Show agenda")
                AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": mainView.calendarApp})
            } else if (selectedMenuItem == cameraLabel) {
                console.log("Springboard | Show camera")
                AN.SystemDispatcher.dispatch("volla.launcher.camAction", new Object)
            } else if (selectedMenuItem == dialerLabel) {
                console.log("Springboard | Show dialer")
                //Qt.openUrlExternally("tel:")
                AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"action": "dial"})
            } else if (selectedMenuItem == notesLabel) {
                console.log("Springboard | Show notes")
                AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": mainView.notesApp})
            } else if (selectedMenuItem == eventLabel) {
                console.log("Springboard | Create event")
                AN.SystemDispatcher.dispatch("volla.launcher.createEventAction", {"title": qsTr("My event")})
            }
        }

        Rectangle {
            id: shortcutBackground
            anchors.bottom: parent.bottom
            anchors.bottomMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0
            anchors.right: parent.right
            anchors.rightMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0
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
            // height: menuheight
            topPadding: mainView.innerSpacing * 1.5
            anchors.bottom: parent.bottom
            anchors.bottomMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0

            property int duration: 200
            property real leftDistance: parent.width / 4

            Label {
                id: dialerLabel
                text: qsTr("Show Dialer")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
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
                text: qsTr("Show Agenda")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: eventLabel
                text: qsTr("Create Event")
                font.pointSize: mainView.largeFontSize
                anchors.left: parent.left
                leftPadding: shortcutColumn.leftDistance
                bottomPadding: mainView.innerSpacing
                color: "white"
            }
            Label {
                id: notesLabel
                text: qsTr("Show Notes")
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
