import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import QtQuick.Window 2.2
import FileIO 1.0
import AndroidNative 1.0 as AN

LauncherPage {
    id: springBoard
    anchors.fill: parent

    property string textInput
    property bool textFocus
    property real menuheight: mainView.largeFontSize * 7 + mainView.innerSpacing * 10.5
    property var textInputArea
    property var selectedObj
    property var headline

    property var eventGlossar: [qsTr("Monday"), qsTr("Tuesday"), qsTr("Wednesday"), qsTr("Thursday"), qsTr("Friday"),
                                qsTr("Saturday"), qsTr("Sunday"), qsTr("tomorrow")]
    property var eventRegex
    property var plugins: new Array

    property bool defaultSuggestions: false
    property bool dotShortcut: true
    property bool roundedShortcutMenu: true

    onTextInputChanged: {
        console.log("Springboard | text input changed")
        listModel.update()
    }

    Component.onCompleted: {
        listModel.update()
        shortcutMenu.updateShortcuts(mainView.getActions())
        var eventRegexStr = "^("
        for (var i = 0; i < eventGlossar.length; i++) {
            eventRegexStr = eventRegexStr.concat(eventGlossar[i])
            if (i < eventGlossar.length - 1) eventRegexStr = eventRegexStr.concat("|")
        }
        eventRegexStr = eventRegexStr.concat(")\\s(\\d{1,2}\\:?\\d{0,2})?-?(\\d{1,2}\\:?\\d{0,2})?\\s?(am|pm|uhr\\s)?(\\S.*)")
        eventRegex = new RegExp(eventRegexStr, "gim")

        var installedPlugins = mainView.getInstalledPlugins()
        for (i = 0; i < installedPlugins.length; i++) {
            addPlugin(mainView.getInstalledPluginSource(installedPlugins[i].id), installedPlugins[i].id)
        }
    }

    Connections {
        target: Qt.inputMethod

        onKeyboardRectangleChanged: {
            console.log("Springboard | Keyboard rectangle: " + Qt.inputMethod.keyboardRectangle)
        }
    }

    function updateShortcuts(actions) {
        shortcutMenu.updateShortcuts(actions)
    }

    function updateShortcutMenuState(opened) {
        if (opened) {
            shortcutMenu.height = shortcutColumn.height + mainView.innerSpacing * 1.5
            shortcutBackground.width = roundedShortcutMenu ? parent.width - mainView.innerSpacing * 4 : parent.width
            shortcutBackground.height = shortcutColumn.height
            shortcutColumn.opacity = 1
        } else {
            shortcutBackground.width = dotShortcut ? mainView.innerSpacing * 2 : parent.width
            shortcutBackground.height = dotShortcut ? mainView.innerSpacing * 2 : mainView.innerSpacing
            shortcutColumn.opacity = 0
            shortcutMenu.executeSelection()
            shortcutMenu.selectedMenuItem = rootMenuButton
            shortcutMenu.height = dotShortcut ? mainView.innerSpacing * 4 : mainView.innerSpacing * 3
        }
    }

    function updateHeadlineColor() {
        springBoard.headline.color = mainView.fontColor
    }

    function addPlugin(pluginSource, pluginId) {
        console.debug("Springboard | Plugin " + pluginId + " source length: " + pluginSource.length)
        //console.debug("Springboard | Plugin " + pluginId + " source: " + pluginSource)
        try {
            var qmlObject = Qt.createQmlObject(pluginSource, springBoard, pluginId)
            console.debug("Springboard | Plugin " + qmlObject.metadata.id + " created")
            springBoard.plugins.push(qmlObject)
        } catch (error) {
            console.debug("Springboard | Error loading QML : ")
            for (var i = 0; i < error.qmlErrors.length; i++) {
                console.debug("Springboard | lineNumber: " + error.qmlErrors[i].lineNumber)
                console.debug("Springboard | columnNumber: " + error.qmlErrors[i].columnNumber)
                console.debug("Springboard | fileName: " + error.qmlErrors[i].fileName)
                console.debug("Springboard | message: " + error.qmlErrors[i].message)
            }
        }
    }

    function removePlugin(pluginId) {
        console.debug("Springboard | Will remove pluding " + pluginId)
        springBoard.plugins = springBoard.plugins.filter(el => el.metadata.id !== pluginId)
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

                Binding {
                    target: springBoard
                    property: "headline"
                    value: headline
                }
            }

            Row {
                width: parent.width

                Flickable {
                    id: flickable
                    width: parent.width - mainView.innerSpacing * 2
                    height: Math.min(contentHeight, 200)
                    contentWidth: width
                    contentHeight: textArea.implicitHeight
                    clip: true
                    flickableDirection: Flickable.VerticalFlick

                    TextArea.flickable: TextArea {
                        id: textArea
                        padding: mainView.innerSpacing
                        x: mainView.innerSpacing
                        width: parent.width
                        placeholderText: qsTr("Type anything")
                        color: mainView.fontColor
                        placeholderTextColor: "darkgrey"
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
                        leftPadding: 0.0
                        inputMethodHints: Qt.ImhNoPredictiveText

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
                    }
                    ScrollBar.vertical: ScrollBar {}
                }

                Button {
                    id: deleteButton
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: mainView.largeFontSize * 2
                    flat: true
                    topPadding: 0.0
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

            property int indexOfFirstSuggestion: -1

            function checkContacts(contact) {
                var fullName = contact["name"].replace(/\s/g, "_")
                return textInput.indexOf(fullName) == 1
            }

            function validateSelectedObject() {
                if (selectedObj === undefined) {
                    console.log("Try to guess contact")
                    var i = textInput.indexOf(" ")
                    var contacts = mainView.getContacts().filter(checkContacts)

                    if (contacts.length === 1) {
                        console.log("Springboard | Found contact")
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

            function parseAndSaveEvent() {
                var d = new Date()
                var pattern1 = /^(\d{1,2})\.(\d{1,2})\.(\d{2,4})?\s(\d{1,2}\:?\d{0,2})?-?(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr\s)?(\S.*)/gim
                var pattern2 = /^(\d{2,4})\/(\d{1,2})\/(\d{1,2})?\s(\d{1,2}\:?\d{0,2})?-?(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr\s)?(\S.*)/gim
                if (eventRegex.test(textInput)) {
                    var day = d.getDay()
                    var plannedDay = eventGlossar.indexOf(textInput.replace(eventRegex, '$1'))
                    var daysToAdd = plannedDay > day ? plannedDay - day : 7 - plannedDay
                    if (plannedDay === 8) daysToAdd = 1
                    var eventDate = new Date()
                    eventDate.setDate(eventDate.getDate() + daysToAdd)
                    var year = eventDate.getFullYear()
                    var date = eventDate.getDate()
                    var month = eventDate.getMonth()
                    var beginhour = textInput.replace(eventRegex, '$2') !== "" ?
                                parseInt(textInput.replace(eventRegex, '$2').split(":")[0]) : -1
                    var beginMinute = beginhour > - 1 && textInput.replace(eventRegex, '$2').split(":")[1] !== undefined ?
                                parseInt(textInput.replace(eventRegex, '$2').split(":")[1]) : 0
                    var endHour = textInput.replace(eventRegex, '$3') !== "" ?
                                parseInt(textInput.replace(eventRegex, '$3').split(":")[0]) : -1
                    var endMinute = beginhour > - 1 && textInput.replace(eventRegex, '$3').split(":")[1] !== undefined ?
                                parseInt(textInput.replace(eventRegex, '$3').split(":")[1]) : 0
                    if (beginhour > -1 && endHour < 0) {
                        endHour = beginhour + 1
                        endMinute = beginMinute
                    }
                    if (textInput.replace(eventRegex, '$4').toLocaleLowerCase() === "pm") {
                        beginhour = beginhour + 12
                        endHour = endHour + 12
                    }
                    var allDay = beginhour < 0
                    var title = textInput.replace(eventRegex, '$5').split("\n",2)[0]
                    var description = textInput.replace(eventRegex, '$5').split("\n",2)[1] !== undefined ?
                                textInput.replace(eventRegex, '$5').split("\n",2)[1] : ""
                } else {
                    var pattern = pattern1.test(textInput) ? pattern1 : pattern2
                    date = parseInt(textInput.replace(pattern, '$1'))
                    month = parseInt(textInput.replace(pattern, '$2')) - 1
                    year = textInput.replace(pattern, '$3') === "" ?
                                d.getFullYear() : parseInt(textInput.replace(pattern, '$3'))
                    if (year < 100) year = 2000 + year
                    beginhour = textInput.replace(pattern, '$4') !== "" ?
                                parseInt(textInput.replace(pattern, '$4').split(":")[0]) : -1
                    beginMinute = beginhour > - 1 && textInput.replace(pattern, '$4').split(":")[1] !== undefined ?
                                parseInt(textInput.replace(pattern, '$4').split(":")[1]) : 0
                    endHour = textInput.replace(pattern, '$5') !== "" ?
                                parseInt(textInput.replace(pattern, '$5').split(":")[0]) : -1
                    endMinute = beginhour > - 1 && textInput.replace(pattern, '$5').split(":")[1] !== undefined ?
                                parseInt(textInput.replace(pattern, '$5').split(":")[1]) : 0
                    if (beginhour > -1 && endHour < 0) {
                        endHour = beginhour + 1
                        endMinute = beginMinute
                    }
                    if (textInput.replace(pattern, '$6').toLocaleLowerCase() === "pm") {
                        beginhour = beginhour + 12
                        endHour = endHour + 12
                    }
                    allDay = beginhour < 0
                    title = textInput.replace(pattern, '$7').split("\n",2)[0]
                    description = textInput.replace(pattern, '$7').split("\n",2)[1] !== undefined ?
                                textInput.replace(pattern, '$7').split("\n",2)[1] : ""
                }

                if (!allDay) {
                    var beginTime = new Date(year, month, date, beginhour, beginMinute, 0 , 0)
                    console.log("Springboard | Start date: " + beginTime)
                    var endTime = new Date(year, month, date, endHour, endMinute, 0 , 0)
                    console.log("Springboard | End date: " + endTime)
                    AN.SystemDispatcher.dispatch("volla.launcher.createEventAction", {
                          "beginTime": beginTime.valueOf(), "endTime": endTime.valueOf(), "allDay": allDay,
                          "title": title, "description": description})
                } else {
                    AN.SystemDispatcher.dispatch("volla.launcher.createEventAction", {
                          "allDay": allDay, "title": title, "description": description})
                }
            }

            function textInputStartsWithPhoneNumber() {
                return /^\+?\d{4,}(\s\S+)?/.test(textInput)
            }

            function textInputStartWithEmailAddress() {
                return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}\s\S+/.test(textInput)
            }

            function executeAction(actionValue, actionType, actionObj, functionReference) {
                if (actionObj !== undefined) {
                    console.log("SpringBoard | Execute selection " + actionValue + ": " + actionType + ": " + actionObj["id"])
                } else {
                    console.log("SpringBoard | Execute selection " + actionValue + ": " + actionType)
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
                            Qt.openUrlExternally("https://metager.de/meta/meta.ger3?eingabe=" + message + "&ref=hellovolla")
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
                        mainView.updateNote(undefined, textInput, false)
                        textInputArea.text = ""
                        mainView.showToast(qsTr("New note saved"))
                        break
                    case mainView.actionType.CreateEvent:
                        parseAndSaveEvent()
                        textInputArea.text = ""
                        mainView.showToast("Event added to calendar")                       
                        break
                    case mainView.actionType.SendSignal:
                        idx = textInput.search(/\s/)
                        message = textInput.substring(idx+1, textInput.length)
                        phoneNumber = selectedObj["phone.signal"]
                        AN.SystemDispatcher.dispatch("volla.launcher.signalIntentAction", {"number": phoneNumber, "text": message})
                        textInputArea.text = ""
                        break
                    case mainView.actionType.OpenSignalContact:
                        phoneNumber = selectedObj["phone.signal"]
                        console.log("Springboard | Will show contact " + phoneNumber + " in Signal")
                        Qt.openUrlExternally("sgnl://signal.me/#p/" + phoneNumber)
                        textInputArea.text = ""
                        break
                    case mainView.actionType.ExecutePlugin:
                        console.log("Springboard | Will execute plugin " + functionReference.pluginId)
                        for (var i = 0; i < springBoard.plugins.length; i++) {
                            if (functionReference.pluginId === springBoard.plugins[i].metadata.id) {
                                if (selectedObj !== undefined) {
                                    springBoard.plugins[i].executeInput(textInput, functionReference.functionId, selectedObj.entity)
                                } else {
                                    springBoard.plugins[i].executeInput(textInput, functionReference.functionId)
                                }
                            }
                        }
                        textInputArea.text = ""
                        break
                    case mainView.actionType.SuggestPluginEntity:
                        console.log("Springboard | Will complete " + textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue)
                        if (actionObj !== undefined && actionValue !== undefined) {
                            springBoard.selectedObj = actionObj
                            textInputArea.text = actionValue
                            textInputArea.cursorPosition = textInput.length
                            textInputArea.forceActiveFocus()
                        } else {
                            mainView.showToast(qsTr("An error occured") + ": " + actionValue + ", " + actionObj)
                            textInputArea.text = ""
                            textInputArea.forceActiveFocus()
                        }
                        break;
                    case mainView.actionType.SuggestContact:
                        console.log("Springboard | Will complete " + textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue)
                        if (actionObj !== undefined && actionValue !== undefined) {
                            springBoard.selectedObj = JSON.parse(JSON.stringify(actionObj))
                            actionValue = "@" + actionValue.replace(/\s/g, "_")
                            textInputArea.text = textInput.substring(0, textInput.lastIndexOf(" ")) + actionValue + " "
                            textInputArea.cursorPosition = textInput.length
                            textInputArea.forceActiveFocus()
                        } else {
                            mainView.showToast(qsTr("An error occured")
                                               + ": " + actionValue + ", " + actionObj
                                               + ". " + qsTr("Please reset contacts and try again."))
                            textInputArea.text = ""
                            textInputArea.forceActiveFocus()
                        }
                        break;
                }
            }

            function update() {
                console.log("Springboard | update model for " + textInput);

                if (textInput.length < 1) {
                    listModel.clear()
                } else {
                    springBoardWorker.sendMessage({
                        'selectedObj': springBoard.selectedObj, 'textInput': textInput,
                        'contacts': mainView.getContacts(), 'model': listModel, 'actionType': mainView.actionType,
                        'actionName': mainView.actionName, 'eventRegex': eventRegex
                    })
                }
            }

            function iteratePlugins(item, length){
                var counter = 0
                var pluginFunctions = new Array
                var autocompletions = new Array
                for (var i = 0; i < length; i++) {
                    console.debug("Springboard | Execute plugin " + springBoard.plugins[i].metadata.id)
                    springBoard.plugins[i].processInput(textInput, function (success, suggestions, pluginId) {
                        var result = suggestions;
                        if (success) {
                            for (var j = 0; j < result.length; j++) {
                                if (result[j].label === undefined || result[j].label.length > 100) {
                                    console.warn("Springboard | Missing or too long label of plugin suggestion")
                                }
                                if (result[j].functionId !== undefined) {
                                    pluginFunctions.push({"text": result[j].label,
                                                          "action": mainView.actionType.ExecutePlugin,
                                                          "functionReference": {"pluginId": pluginId, "functionId": result[j].functionId},
                                                          "isFirstSuggestion": false })
                                } else {
                                    autocompletions.push({"text": result[j].label,
                                                          "action": mainView.actionType.SuggestPluginEntity,
                                                          "object": {'pluginId': pluginId, 'entity': result[j].object },
                                                          "isFirstSuggestion": false })
                                }
                            }
                            if (counter++ === length -1) {
                                listModel.indexOfFirstSuggestion = listModel.indexOfFirstSuggestion + pluginFunctions.length
                                console.debug("Springboard | listModel.indexOfFirstSuggestion" + listModel.indexOfFirstSuggestion )
                                for (i = 0; i < pluginFunctions.length; i++) {
                                    if (selectedObj === undefined || (selectedObj !== undefined && selectedObj.pluginId !== undefined
                                                                      && selectedObj.pluginId === pluginFunctions[i].functionReference.pluginId)) {
                                        console.debug("Springboard | Appending plugin function: " + pluginFunctions[i].functionReference.pluginId)
                                        listView.model.insert(0, pluginFunctions[i])
                                    }
                                }
                                for (i = 0; i < autocompletions.length; i++) {
                                    console.debug("Springboard | Appending plugin suggestion: " + autocompletions[i].object)
                                    listView.model.append(autocompletions[i])
                                }
                            }
                        } else{
                            console.debug("Springboard | Plugin returned success false")
                        }
                    })
                }
            }
        }

        currentIndex: -1 // otherwise currentItem will steal focus

        delegate: Rectangle {
            id: backgroundItem

            height: button.height
            width: parent.width
            color: model.action < 20000 ? "transparent" : mainView.accentColor
            Button {
                id: button
                width: parent.width - mainView.innerSpacing
                leftPadding: mainView.innerSpacing
                topPadding: model.index === 0 || model.index === listModel.indexOfFirstSuggestion ? mainView.innerSpacing : 0
                bottomPadding: model.index === listModel.count - 1 || model.index === listModel.indexOfFirstSuggestion - 1
                               ? mainView.innerSpacing : mainView.innerSpacing / 2
                anchors.top: parent.top
                text: styledText(model.text, textInput.substring(textInput.indexOf("@") === 0 ? 1 : 0, textInput.length))
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
                    if (model["functionReference"] !== undefined) {
                        console.debug("Springboard | Function: " + model.functionReference.pluginId)
                        listModel.executeAction(model.text, model.action, new Object, model.functionReference)
                    } else {
                        console.debug("Springboard | Object: " + model.object)
                        listModel.executeAction(model.text, model.action, model.object)
                    }
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

            onMessage: {
                console.log("Springboard | Main worker script finished")
                console.log("Springboard | Number of plugins: " + springBoard.plugins.length)

                listModel.indexOfFirstSuggestion = messageObject['indexOfFirstSuggestion']
                if(plugins.length > 0){
                    listModel.iteratePlugins(0, plugins.length)
                }
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
            var componentWidth = Screen.width - leftDistance
            console.log("Springboard | Width " + componentWidth)
            for (var i = 0; i < shortcuts.length; i++) {
                if (shortcuts[i]["activated"]) {
                    var component = Qt.createComponent("/Shortcut.qml", shortcutColumn)
                    var properties = { "actionId": shortcuts[i]["id"],
                        "text": shortcuts[i]["name"],
                        "labelFontSize": mainView.largeFontSize,
                        "leftPadding": leftDistance,
                        "bottomPadding": mainView.innerSpacing,
                        "width": componentWidth }
                    if (component.status !== Component.Ready) {
                        if (component.status === Component.Error)
                            console.debug("Springboard | Error: "+ component.errorString() )
                    }
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
                case mainView.actionType.ShowThreads:
                    console.log("Springboard | Show threads")
                    collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                    mainView.updateCollectionPage(mainView.collectionMode.Threads)
                    break
                case mainView.actionType.ShowNews:
                    console.log("Springboard | Show news")
                    collectionPage = Qt.createComponent("/Collections.qml", springBoard)
                    mainView.updateCollectionPage(mainView.collectionMode.News)
                    break
                case mainView.actionType.ShowGallery:
                    console.log("Springboard | Show gallery " + mainView.galleryApp)
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
                    //AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": mainView.notesApp})
                    mainView.updateCollectionPage(mainView.collectionMode.Notes)
                    break
                case mainView.actionType.CreateEvent:
                    console.log("Springboard | Create event")
                    AN.SystemDispatcher.dispatch("volla.launcher.createEventAction", {"title": qsTr("My event")})
                    break
                default:
                    console.log("Springboard | Open app or shortcut")
                    if (selectedMenuItem.actionId.startsWith("http")) {
                        // Workaround for web shortcuts
                        Qt.openUrlExternally(selectedMenuItem.actionId)
                    } else {
                        AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": selectedMenuItem.actionId})
                    }
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
            color: mainView.accentColor
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
            color: mainView.accentColor
            radius: dotShortcut ? width * 0.5 : 0.0
            anchors.right: parent.right
            anchors.rightMargin: dotShortcut ? mainView.innerSpacing * 2 : 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dotShortcut ? mainView.innerSpacing * 2 : 0
        }
    }
}
