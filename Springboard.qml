import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import QtQuick.Window 2.2
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
                    case mainView.actionType.SendEmailToWork:
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

                        settings.sync()

                        switch (mainView.getSearchMode()) {
                        case mainView.searchMode.StartPage:
                            Qt.openUrlExternally("https://startpage.com/sp/search?query=" + message + "&segment=startpage.volla")
                            break
                        case mainView.searchMode.MetaGer:
                            Qt.openUrlExternally("https://metager.de/meta/meta.ger3?eingabe=" + message)
                            break
                        default:
                            Qt.openUrlExternally("https://duck.com?q=" + message)
                        }
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
        height: dotShortcut ? mainView.innerSpacing * 4 : mainView.innerSpacing * 3
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        preventStealing: true
        enabled: !textInputArea.activeFocus && !defaultSuggestions

        property var selectedMenuItem: rootMenuButton

        onSelectedMenuItemChanged: {
            for (var i = 0; i < shortcutColumn.shortcutLabels.length; i++) {
                var shortcutLabel = shortcutColumn.shortcutLabels[i]
                shortcutLabel.font.bold = selectedMenuItem === shortcutLabel
                shortcutLabel.font.pointSize = selectedMenuItem === shortcutLabel ? mainView.largeFontSize * 1.2 : mainView.largeFontSize
            }

            if (selectedMenuItem !== rootMenuButton && mainView.useVibration) {
                AN.SystemDispatcher.dispatch("volla.launcher.vibrationAction", {"duration": mainView.vibrationDuration})
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
            var selectedItem = rootMenuButton

            for (var i = 0; i < shortcutColumn.shortcutLabels.length; i++) {
                var shortcutLabel = shortcutColumn.shortcutLabels[i]
                var lPoint = mapFromItem(shortcutLabel, 0, 0)
                if (lPoint.y && mouseY < lPoint.y + shortcutLabel.height) {
                    selectedItem = shortcutLabel
                    break
                }
            }

            if (selectedMenuItem !== selectedItem) {
                console.log("Springboard | Update selected meneu item to " + selectedItem.text)
                selectedMenuItem = selectedItem
            }
        }        

        function createShortcuts(shortcuts) {
            var leftDistance = Screen.width / 4
            console.log("SpringBoard | Left distance is " + leftDistance)
            for (var i = 0; i < shortcuts.length; i++) {
                if (shortcuts[i]["activated"]) {
                    var component = Qt.createComponent("/Shortcut.qml", shortcutColumn)
                    var properties = { "actionId": shortcuts[i]["id"],
                        "text": shortcuts[i]["name"],
                        "labelFontSize": mainView.largeFontSize,
                        "leftPadding": leftDistance,
                        "bottomPadding": mainView.innerSpacing }
                    var object = component.createObject(shortcutColumn, properties)
                    shortcutColumn.shortcutLabels.push(object)
                }
            }
        }

        function destroyShortcuts() {
            for (var i = 0; i < shortcutColumn.shortcutLabels.length; i++) {
                var shortcutLabel = shortcutColumn.shortcutLabels[i]
                shortcutLabel.destroy()
            }
            shortcutColumn.shortcutLabels = new Array
        }

        function updateShortcuts(actions) {
            destroyShortcuts()
            createShortcuts(actions)

//            actions.forEach(function (action, index) {
//                switch (action.id) {
//                    case mainView.actionType.OpenCam:
//                        cameraLabel.visible = action.activated
//                        break
//                    case mainView.actionType.ShowCalendar:
//                        agendaLabel.visible = action.activated
//                        break
//                    case mainView.actionType.ShowGallery:
//                        galleryLabel.visible = action.activated
//                        break
//                    case mainView.actionType.ShowNotes:
//                        notesLabel.visible = action.activated
//                        break
//                    case mainView.actionType.CreateEvent:
//                        eventLabel.visible = action.activated
//                        break
//                    case mainView.actionType.ShowContacts:
//                        peopleLabel.visible = action.activated
//                        break
//                    case mainView.actionType.ShowThreads:
//                        threadLabel.visible = action.activated
//                        break
//                    case mainView.actionType.ShowNews:
//                        newsLabel.visible = action.activated
//                        break
//                }
//            })
        }

        function executeSelection() {
            console.log("Springboard | Action ID is " + selectedMenuItem.actionId)

            if (shortcutColumn.opacity === 0.0 || selectedMenuItem.actionId === undefined) {
                return;
            }

            switch (selectedMenuItem.actionId) {
                case mainView.actionType.ShowContacts:
                    console.log("Springboard | Show people")
                    var collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                    mainView.updateCollectionPage(mainView.collectionMode.People)
                    break
                case mainView.actionType.ShoewThreads:
                    console.log("Springboard | Show threads")
                    collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                    mainView.updateCollectionPage(mainView.collectionMode.Threads)
                    break
                case mainView.actionType.ShowNews:
                    console.log("Springboard | Show news")
                    collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                    mainView.updateCollectionPage(mainView.collectionMode.News)
                    break
                case mainView.actionType.ShoeGallery:
                    console.log("Springboard | Show gallery")
                    AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": mainView.galleryApp})
                    break
                case mainView.actionType.ShowCalendar:
                    console.log("Springboard | Show agenda")
                    AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": mainView.calendarApp})
                    break
                case mainView.actionType.OpenCam:
                    console.log("Springboard | Show camera")
                    AN.SystemDispatcher.dispatch("volla.launcher.camAction", new Object)
                    break
                case mainView.actionType.ShowDialer:
                    console.log("Springboard | Show dialer")
                    AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp, "action": "dial"})
                    break
                case mainView.actionType.ShowNotes:
                    console.log("Springboard | Show notes")
                    AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": mainView.notesApp})
                    break
                case mainView.actionType.CreateEvent:
                    console.log("Springboard | Create event")
                    AN.SystemDispatcher.dispatch("volla.launcher.createEventAction", {"title": qsTr("My event")})
                    break
                default:
                    console.log("Springboard | Open App")
                    AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": selectedMenuItem.actionId})
                    break
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
            bottomPadding: mainView.innerSpacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0

            property int duration: 200
            property var shortcutLabels: new Array

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
