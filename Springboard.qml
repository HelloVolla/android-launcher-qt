import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import QtQuick.Window 2.2
import QtGraphicalEffects 1.12
import QtPositioning 5.11
import Qt.labs.settings 1.0
import FileIO 1.0
import AndroidNative 1.0 as AN

LauncherPage {
    id: springBoard
    anchors.fill: parent

    property string textInput
    property bool textFocus
    property real menuheight: mainView.largeFontSize * 7 + mainView.innerSpacing * 10.5
    property real menuWidth: 400.0
    property var textInputArea
    property var selectedObj
    property var headline

    property var eventGlossar: [qsTr("Sunday"), qsTr("Monday"), qsTr("Tuesday"), qsTr("Wednesday"), qsTr("Thursday"), qsTr("Friday"),
                                qsTr("Saturday"), qsTr("tomorrow")]
    property var eventRegex
    property var plugins: new Array
    property var appButtons: new Array

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
            eventRegexStr = eventRegexStr.concat(eventGlossar[i].toLowerCase())
            if (i < eventGlossar.length - 1) eventRegexStr = eventRegexStr.concat("|")
        }
        eventRegexStr = eventRegexStr.concat(")\\s(\\d{1,2}\\:?\\d{0,2})\\s?(am|pm|uhr)?(\\s-\\s)?(\\d{1,2}\\:?\\d{0,2})?\\s(am|pm|uhr)?\\s?(\\S(.*\\n?)*)")
        eventRegex = new RegExp(eventRegexStr, "im")

        var installedPlugins = mainView.getInstalledPlugins()
        for (i = 0; i < installedPlugins.length; i++) {
            addPlugin(mainView.getInstalledPluginSource(installedPlugins[i].id), installedPlugins[i].id)
        }
    }

    Connections {
        target: Qt.inputMethod

        onKeyboardRectangleChanged: {
            console.debug("Springboard | Keyboard rectangle: " + Qt.inputMethod.keyboardRectangle + ", focus: " + textInputArea.activeFocus)
            if (Qt.rect(0, 0, 0, 0) === Qt.inputMethod.keyboardRectangle && textInputArea.activeFocus) {
                console.debug("Springboard | Reactivate keyboard")
                Qt.inputMethod.show()
            }
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

    function updateWidgets(widgetId, isVisible) {
        widgetsSettings.sync()

        switch (widgetId) {
            case 0:
                widgetsSettings.weatherWidgetIsVisible = isVisible
                break
            case 1:
                widgetsSettings.clockWidgetIsVisible = isVisible
                break
            case 2:
                widgetsSettings.noteWidgetIsVisible = isVisible
                break
            default:
                break
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
                        topPadding: mainView.componentSpacing
                        bottomPadding: mainView.innerSpacing
                        leftPadding: 0.0
                        rightPadding: mainView.innerSpacing
                        x: mainView.innerSpacing
                        width: parent.width
                        placeholderText: qsTr("Type anything")
                        color: mainView.fontColor
                        placeholderTextColor: "darkgrey"
                        font.pointSize: mainView.largeFontSize
                        wrapMode: Text.WordWrap
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
                    anchors.top: flickable.top
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: mainView.largeFontSize * 2
                    flat: true
                    topPadding: mainView.innerSpacing === mainView.componentSpacing ? 0.0 : 18.0
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
            property int indexOfFirstFunction: -1

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

                if (eventRegex.test(textInput)) {
                    console.debug("Springboard | Inpus: " + textInput)
                    var matches = eventRegex.exec(textInput)
                    for (var i = 0; i < matches.length; i++) {
                        console.debug("Springboard | " + i + " group: " + matches[i])
                    }
                    var day = d.getDay()
                    var plannedDay = eventGlossar.indexOf(matches[0].toLowerCase())
                    var daysToAdd = plannedDay > day ? plannedDay - day : 7 - plannedDay
                    if (daysToAdd === 8) daysToAdd = 1
                    var eventDate = new Date()
                    eventDate.setDate(eventDate.getDate() + daysToAdd)
                    var year = eventDate.getFullYear()
                    var date = eventDate.getDate()
                    var month = eventDate.getMonth()
                    var beginhour = matches[1] !== undefined ? parseInt(matches[1].split(":")[0]) : -1
                    var beginMinute = beginhour > - 1 && matches[1].split(":")[1] !== undefined ? parseInt(matches[1].split(":")[1]) : 0
                    var endHour = matches[5] !== undefined ? parseInt(matches[5].split(":")[0]) : -1
                    var endMinute = beginhour > - 1 && matches[5].split(":")[1] !== undefined ? parseInt(matches[5].split(":")[1]) : 0
                    if (beginhour > -1 && endHour < 0) {
                        endHour = beginhour + 1
                        endMinute = beginMinute
                    }
                    if (matches[3] !== undefined && matches[3].toLowerCase === "pm") beginhour = beginhour + 12
                    if (matches[6] !== undefined && matches[6].toLowerCase === "pm") endHour = endHour + 12
                    var allDay = beginhour < 0
                    var title = matches[7] !== undefined ? matches[7].split("\n",2)[0]: ""
                    var description = matches[7] !== undefined && matches[7].split("\n",2)[1] !== undefined ? matches[7].split("\n",2)[1] : ""
                } else {
                    var pattern1 = /^(\d{1,2})\.(\d{1,2})\.(\d{2,4})?\s(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr)?(\s?-\s?)?(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr)?\s?(\S(.*\n?)*)/im
                    var pattern2 = /^(\d{2,4})\/(\d{1,2})\/(\d{1,2})?\s(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr)?(\s?-\s?)?(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr)?\s?(\S(.*\n?)*)/im
                    var pattern = pattern1.test(textInput) ? pattern1 : pattern2
                    matches = pattern.exec(textInput)
                    for (i = 0; i < matches.length; i++) {
                        console.debug("Springboard | " + i + " group: " + matches[i])
                    }
                    date = parseInt(matches[1])
                    month = parseInt(matches[2]) - 1
                    year = matches[3] === undefined ? d.getFullYear() : parseInt(matches[3])
                    if (year < 100) year = 2000 + year
                    beginhour = matches[4] !== undefined ? parseInt(matches[4].split(":")[0]) : -1
                    beginMinute = beginhour > - 1 && matches[4].split(":")[1] !== undefined ? parseInt(matches[4].split(":")[1]).split(":")[1] : 0
                    if (matches[5] !== undefined && matches[5].toLowerCase() === "pm") beginhour = beginhour + 12
                    endHour = matches[7]  !== undefined ? parseInt(matches[7].split(":")[0]) : -1
                    endMinute = endHour > - 1 && matches[6].split(":")[1] !== undefined ? parseInt(matches[6].split(":")[1]) : 0
                    if (matches[8] !== undefined && matches[8].toLowerCase() === "pm") {
                        if (matches[5] === undefined) beginhour = beginhour + 12
                        endHour = endHour + 12
                    }
                    if (beginhour > -1 && endHour < 0) {
                        endHour = beginhour + 1
                        endMinute = beginMinute
                    }
                    allDay = beginhour < 0
                    title = matches[9] !== undefined ? matches[9].split("\n",2)[0] : ""
                    description = title.split("\n",2)[1] !== undefined ? title.split("\n",2)[1] : ""
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

            function executeAction(actionValue, actionType, actionObj) {
                if (actionObj !== undefined) {
                    var octionObjId = actionObj.id !== undefined ? actionObj.id : actionObj.pluginId
                    console.log("SpringBoard | Execute selection " + actionValue + ": " + actionType + ": object " + octionObjId)
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
                        case mainView.searchMode.Custom:
                            Qt.openUrlExternally(mainView.searchEngineUrl + message)
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
                        console.log("Springboard | Will execute plugin " + actionObj.pluginId)
                        for (var i = 0; i < springBoard.plugins.length; i++) {
                            if (actionObj.pluginId === springBoard.plugins[i].metadata.id) {
                                if (selectedObj !== undefined) {
                                    springBoard.plugins[i].executeInput(textInput, actionObj.functionId, selectedObj.entity)
                                } else {
                                    springBoard.plugins[i].executeInput(textInput, actionObj.functionId)
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
                    case mainView.actionType.LiveContentPlugin:
                        if (actionObj.link !== undefined && actionObj.link.length > 0) {
                            console.debug("Springboard | Will open link '" + actionObj.link + "' of plugin " + actionObj.pluginId)
                            Qt.openUrlExternally(actionObj.link)
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
                    console.debug("Springboard | Will clear property")
                    selectedObj = undefined
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
                var liveContent = new Array

                for (var i = 0; i < length; i++) {
                    console.debug("Springboard | Execute plugin " + springBoard.plugins[i].metadata.id)
                    if (selectedObj !== undefined)
                        console.debug("Springboard | " + selectedObj.pluginId)
                    springBoard.plugins[i].processInput(springBoard.textInput, function (success, suggestions, pluginId) {
                        var result = suggestions;
                        if (success) {
                            for (var j = 0; j < result.length; j++) {
                                if (result[j].label === undefined || result[j].label.length > 1000) {
                                    console.warn("Springboard | Missing or too long label of plugin suggestion")
                                    console.debug("Springboard | Suggestion: " + result[j].label)
                                }
                                // plugin provides a function suggestion
                                if (result[j].functionId !== undefined) {
                                    pluginFunctions.push({
                                         "text": result[j].label,
                                         "action": mainView.actionType.ExecutePlugin,
                                         "actionObj": {"pluginId": pluginId, "functionId": result[j].functionId},
                                         "isFirstSuggestion": false
                                    })
                                // plugin provides an autocompletion and entity suggestion
                                } else if (result[j].object !== undefined) {
                                    autocompletions.push({
                                        "text": result[j].label,
                                        "action": mainView.actionType.SuggestPluginEntity,
                                        "actionObj": {'pluginId': pluginId, 'entity': result[j].object },
                                        "isFirstSuggestion": false
                                    })
                                // plugin provides live content
                                } else {
                                    liveContent.push({
                                        "text": result[j].label,
                                        "action": mainView.actionType.LiveContentPlugin,
                                        "actionObj": {"pluginId": pluginId, "link": result[j].link !== undefined ? result[j].link : ""},
                                        "isFirstSuggestion": false
                                    })
                                }
                            }
                            // group suggestions
                            if (counter++ === length -1) {
                                listModel.indexOfFirstSuggestion = listModel.indexOfFirstSuggestion + pluginFunctions.length + liveContent.length
                                listModel.indexOfFirstFunction = liveContent.length
                                console.debug("Springboard | listModel.indexOfFirstSuggestion" + listModel.indexOfFirstSuggestion )
                                for (i = 0; i < pluginFunctions.length; i++) {
                                    if (selectedObj === undefined || (selectedObj !== undefined && selectedObj.pluginId !== undefined
                                                                      && selectedObj.pluginId === pluginFunctions[i].actionObj.pluginId)) {
                                        console.debug("Springboard | Appending plugin function: " + pluginFunctions[i].actionObj.pluginId)
                                        listView.model.insert(0, pluginFunctions[i])
                                    }
                                }
                                for (i = 0; i < liveContent.length; i++) {
                                    if (selectedObj === undefined || (selectedObj !== undefined && selectedObj.pluginId !== undefined
                                            && selectedObj.pluginId === liveContent[i].actionObj.pluginId)) {
                                        console.debug("Springboard | Appending plugin live content: " + liveContent[i].actionObj.pluginId)
                                        listView.model.insert(0, liveContent[i])
                                    }
                                }
                                for (i = 0; i < autocompletions.length; i++) {
                                    console.debug("Springboard | Appending plugin suggestion: " + autocompletions[i].object)
                                    listView.model.append(autocompletions[i])
                                }
                            }
                        } else {
                            console.debug("Springboard | Plugin returned success false")
                        }
                    }, selectedObj !== undefined && selectedObj.pluginId !== undefined ? selectedObj : undefined)
                }
            }
        }

        currentIndex: -1 // otherwise currentItem will steal focus

        delegate: Rectangle {
            id: backgroundItem
            height: button.height
            width: parent.width
            color: model.action < 20000 ? "transparent" :
                                          model.action < 20029 ? mainView.accentColor
                                                               : "slategrey"

            Button {
                id: button
                width: parent.width - mainView.innerSpacing
                leftPadding: mainView.innerSpacing
                topPadding: model.index === 0 || model.index === listModel.indexOfFirstSuggestion
                            || model.index === listModel.indexOfFirstFunction ? mainView.innerSpacing : 0
                bottomPadding: model.index === listModel.count - 1 || model.index === listModel.indexOfFirstSuggestion - 1
                               ? mainView.innerSpacing : mainView.innerSpacing / 2
                anchors.top: parent.top
                text: styledText(model.text, textInput.substring(textInput.indexOf("@") === 0 ? 1 : 0, textInput.length))
                contentItem: Text {
                    text: button.text
                    elide: Text.ElideRight
                    font.pointSize: mainView.largeFontSize
                    color: model.action < 20000 ? Universal.foreground : "white"
                    wrapMode: Text.WordWrap
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
                    console.debug("Springboard | Action: " + model.action + ", text: " + model.text + ", object: " + model.actionObj)
                    listModel.executeAction(model.text, model.action, listView.model.get(index).actionObj)
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
                } else if (type === "volla.launcher.runningAppsResponse") {
                    console.log("Springboard | " + message["apps"].length + " running apps received")
                    for (var i = 0; i < springBoard.appButtons.length; i++) {
                        var appButton = springBoard.appButtons[i]
                        appButton.destroy()
                    }
                    closeAppsButton.visible = false
                    springBoard.appButtons = new Array
                    for (i = 0; i < message["apps"].length; i++) {
                        var app = message["apps"][i]
                        console.log("Springboard | Will create app button " + app.package)
                        var component = Qt.createComponent("/AppButton.qml", appSwitcher)
                        var properties = { "app": app,
                                           "height": mainView.innerSpacing * 2,
                                           "width":  mainView.innerSpacing * 2,
                                           "iconSource": app.package in mainView.iconMap
                                                         ? Qt.resolvedUrl(mainView.iconMap[app.package])
                                                         : ("data:image/png;base64," + app.icon),
                                           "hasColoredIcon": mainView.useColoredIcons }
                        if (component.status !== Component.Ready) {
                            if (component.status === Component.Error)
                                console.debug("Springboard | Error: "+ component.errorString() );
                        }
                        var object = component.createObject(appSwitcher, properties)
                        appButtons.push(object)
                        closeAppsButton.visible = true
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
                if (plugins.length > 0){
                    listModel.iteratePlugins(0, plugins.length)
                }
            }
        }
    }

    Flow {
        id: widgetsFlow
        visible: mainView.isTablet && listModel.count === 0
        width: parent.width - mainView.innerSpacing
        layoutDirection: Qt.RightToLeft
        spacing: mainView.innerSpacing
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: mainView.innerSpacing
        anchors.bottomMargin: dotShortcut ? mainView.innerSpacing * 2 : 0

        property double sideLength: 180

        Rectangle {
            id: weatherWidget
            color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
            border.color: "grey"
            width: widgetsFlow.sideLength
            height: widgetsFlow.sideLength
            visible: widgetsSettings.weatherWidgetIsVisible

            property string apiKey: "488297aabb1676640ac7fc10a6c5a2d1"
            property string city: weatherSettings.city
            property double longitude:  weatherSettings.longitude
            property double latitude: weatherSettings.latitude
            property bool isManuallyDefined: weatherSettings.isManuallyDefined

            PositionSource {
                id: src
                updateInterval: 60000
                active: true

                function roundNumber(num, dec) {
                  return Math.round(num * Math.pow(10, dec)) / Math.pow(10, dec)
                }

                onPositionChanged: {
                    var coord = src.position.coordinate
                    var newLongitude = roundNumber(coord.longitude, 3)
                    var newLatitude = roundNumber(coord.latitude, 3)
                    console.debug("Widget | Position changed")
                    console.debug("Widget | PositionSource isActive: " + src.active)
                    console.debug("Widget | Position isManuallyDefinded: " + weatherWidget.isManuallyDefined)
                    console.debug("Widget | isValid: " + coord.isValid)
                    console.debug("Widget | coord: " + coord.longitude + ", " + coord.latitude)
                    if (weatherWidget.visible && !weatherWidget.isManuallyDefined && coord.isValid &&
                        (Math.abs(mainView.longitude - newLongitude) >= 0.10 || Math.abs(mainView.latitude - newLatitude) >= 0.10)) {
                        console.debug("Widget | Will update weather")

                        weatherWidget.latitude = coord.latitude;
                        weatherWidget.longitude = coord.longitude;
                        console.debug("Widget | new ccord: " + newLongitude + ", " + newLatitude)
                        console.debug("Widget | old ccord: " + weatherWidget.longitude + ", " + weatherWidget.latitude)
                        if (!isNaN(newLongitude)) weatherWidget.longitude = newLongitude
                        if (!isNaN(newLatitude)) weatherWidget.latitude = newLatitude
                        weatherWidget.getLocation()
                        weatherWidget.getWeather()
                    }
                }
            }

            Column {
                width: parent.width
                padding: mainView.innerSpacing * 0.5

                Button {
                    id: cityName
                    flat: true

                    contentItem: Label {
                        color: Universal.foreground
                        font.pointSize: mainView.mediumFontSize
                        text: weatherWidget.city
                        elide: Text.ElideRight
                    }

                    onClicked: {
                        console.debug("Widget | Clicked")
                        locatioDialog.open()
                    }
                }

                Button {
                    flat: true
                    width: parent.width
                    contentItem: Column {
                        width: weatherWidget.width

                        Row {
                            id: weatherReport
                            width: parent.width

                            Image {
                                id: weatherImage
                                height: 60
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                id: recentTemperature
                                height: 60
                                color: Universal.foreground
                                font.pointSize: mainView.largeFontSize
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text {
                            id: dayTemperatures
                            width: parent.width
                            topPadding: mainView.innerSpacing * 0.5
                            color: Universal.foreground
                            font.pointSize: mainView.smallFontSize
                            opacity: 0.6
                        }
                    }

                    onClicked: {
                        console.debug("Widget | Will open website for weather report")
                        Qt.openUrlExternally("https://startpage.com/sp/search?query=" + qsTr("weather") + " " + weatherWidget.city + "&segment=startpage.volla")
                    }
                }
            }

            Dialog {
                 id: locatioDialog
                 title: qsTr("Set location")
                 standardButtons: Dialog.Ok | Dialog.Cancel
                 padding: mainView.innerSpacing
                 spacing: mainView.innerSpacing
                 width: 400
                 height: 400
                 anchors.centerIn: Overlay.overlay

                 property string locationInput
                 property var geoRequest: new XMLHttpRequest()

                 onLocationInputChanged: {
                     locatioDialog.geoRequest.abort()
                     getGeoCodes(locationInput)
                 }

                 TextField {
                     id: locationField
                     width: parent.width
                     placeholderText: qsTr("Enter any location")
                     color: mainView.fontColor
                     background: Rectangle {
                         color: mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
                         border.color: "transparent"
                     }
                     Binding {
                         target: locatioDialog
                         property: "locationInput"
                         value: locationField.displayText.toLowerCase()
                     }
                 }

                 ListView {
                     id: locationList
                     anchors.topMargin: mainView.innerSpacing
                     anchors.top: locationField.bottom
                     width: parent.width
                     height: locatioDialog.height - locationField.height - 2 * locatioDialog.padding - locatioDialog.spacing

                     delegate: Button {
                         width: parent.width
                         flat: true
                         contentItem: Text {
                             text: model.city
                             color: mainView.fontColor
                             horizontalAlignment: Text.AlignLeft
                         }
                         onClicked: {
                             weatherWidget.city = model.city
                             weatherWidget.longitude = model.lon
                             weatherWidget.latitude = model.lat
                             weatherSettings.isManuallyDefined = true
                             weatherSettings.city = model.city
                             weatherSettings.longitude = model.lon
                             weatherSettings.latitude = model.lat
                             weatherSettings.sync()
                             console.debug("Widget | Setting saved: " + weatherSettings.city)
                             weatherWidget.getWeather()
                             locatioDialog.close()
                             locationModel.clear()
                         }
                     }

                     model: ListModel {
                         id: locationModel

                         function update(modelArr) {
                             console.debug("Widget | Update model: " + modelArr.length)

                             var filteredModelDict = new Object
                             var filteredModelItem
                             var modelItem
                             var found
                             var i

                             for (i = 0; i < modelArr.length; i++) {
                                 filteredModelDict[modelArr[i].city] = modelArr[i]
                             }

                             var existingItemDict = new Object
                             for (i = 0; i < count; ++i) {
                                 var modelItemName = get(i).city
                                 existingItemDict[modelItemName] = true
                             }

                             // remove items no longer in filtered set
                             i = 0
                             while (i < count) {
                                 modelItemName = get(i).city
                                 found = filteredModelDict.hasOwnProperty(modelItemName)
                                 if (!found) {
                                     console.log("Collections | Remove " + modelItemName)
                                     remove(i)
                                 } else {
                                     i++
                                 }
                             }

                             // add new items
                             for (modelItemName in filteredModelDict) {
                                 found = existingItemDict.hasOwnProperty(modelItemName)
                                 if (!found) {
                                     // for simplicity, just adding to end instead of corresponding position in original list
                                     filteredModelItem = filteredModelDict[modelItemName]
                                     console.log("Widget | Will append " + filteredModelItem.city)
                                     append(filteredModelDict[modelItemName])
                                 }
                             }
                         }
                     }
                 }

                 function getGeoCodes(city) {
                     console.debug("Widget | Will request cities: " + city)
                     var geoUrl = "http://api.openweathermap.org/geo/1.0/direct?q=" + city + "&limit=20&appid=" + weatherWidget.apiKey
                     geoRequest.onreadystatechange = function() {
                         if (geoRequest.readyState === XMLHttpRequest.DONE) {
                             console.debug("Widget | Geo location response: " + geoRequest.status)
                             if (geoRequest.status === 200) {
                                 var geoLocations = new Array
                                 var cities = JSON.parse(geoRequest.responseText)
                                 var locale = Qt.locale().name.split('_')[0]
                                 for (var i = 0; i < cities.length; i++) {
                                     city = cities[i].hasOwnProperty("local_names") ? cities[i]["local_names"][locale] : cities[i].name
                                     if (city === undefined) city = cities[i].name
                                     console.debug("Widget | City: " + city)
                                     var lat = cities[i].lat
                                     var lon = cities[i].lon
                                     geoLocations.push({"city": city, "lat": lat, "lon": lon})
                                 }
                                 locationModel.update(geoLocations)
                             } else {
                                 console.error("Widget | Error retrieving weather: ", cityRequest.status, cityRequest.statusText)
                                 locationModel.update(new Array)
                             }
                         }
                     }
                     geoRequest.open("GET", geoUrl)
                     geoRequest.send()
                 }
            }

            function getLocation() {
                console.debug("Widget | Will request city name for " + weatherWidget.latitude, weatherWidget.longitude)
                var cityUrl = "http://api.openweathermap.org/geo/1.0/reverse?lat="
                        + weatherWidget.latitude + "&lon=" + weatherWidget.longitude + "&appid=" + apiKey
                var cityRequest = new XMLHttpRequest()
                cityRequest.onreadystatechange = function() {
                    if (cityRequest.readyState === XMLHttpRequest.DONE) {
                        console.debug("Widget | Location response: " + cityRequest.status)
                        if (cityRequest.status === 200) {
                            var cities = JSON.parse(cityRequest.responseText)
                            console.debug("Widget | Raw: " + cityRequest.responseText)
                            var locale = Qt.locale().name.split('_')[0]
                            if (cities.length > 0) {
                                var city = cities[0].hasOwnProperty("local_names") ? cities[0]["local_names"][locale] : cities[0].name
                            }
                            console.debug("Widget | City: " + city)
                            if (city !== undefined) weatherWidget.city = city
                        } else {
                            console.error("Widget | Error retrieving location: ", cityRequest.status, cityRequest.statusText)
                        }
                    }
                }
                cityRequest.open("GET", cityUrl)
                cityRequest.send()
            }

            function getWeather() {
                console.debug("Widget | Will request weather")
                var weatherUrl = "https://api.openweathermap.org/data/2.5/weather?lat=" + weatherWidget.latitude
                        + "&lon=" + weatherWidget.longitude + "&units=metric&appid=" + apiKey
                console.debug("Widget | Servie URL " + weatherUrl)
                var weatherRequest = new XMLHttpRequest()
                weatherRequest.onreadystatechange = function() {
                    if (weatherRequest.readyState === XMLHttpRequest.DONE) {
                        console.debug("Widget | Weather response: " + weatherRequest.status)
                        if (weatherRequest.status === 200) {
                            var weather = JSON.parse(weatherRequest.responseText)
                            weatherImage.source = "https://openweathermap.org/img/wn/" + weather.weather[0].icon + "@2x.png"
                            recentTemperature.text = weather.main.temp + "°C"
                            dayTemperatures.text = weather.main.temp_min + "°C - " + weather.main.temp_max + "°C"
                        } else {
                            console.error("Widget | Error retrieving weather: ", weatherRequest.status, weatherRequest.statusText)
                        }
                    }
                }
                weatherRequest.open("GET", weatherUrl)
                weatherRequest.send()
            }

            Timer {
                id: weather30MinuteTimer
                interval: 1800000  // 30 minutes in milliseconds (30 * 60 * 1000)
                repeat: weatherWidget.visible      // Set to true to repeat every 30 minutes
                running: weatherWidget.visible     // Start the timer immediately
                triggeredOnStart: true
                onTriggered: {
                    console.debug("Widget | Weather triggered")
                    weatherWidget.getWeather();  // Call the function to execute service
                }
            }

            Settings {
                id: weatherSettings
                property string city: "Remscheid"
                property double longitude: 7.1925
                property double latitude: 51.1798
                property bool isManuallyDefined: false

                Component.onCompleted: {
                    weatherWidget.isManuallyDefined = weatherSettings.isManuallyDefined
                    if (weatherSettings.isManuallyDefined && weatherWidget.city !== weatherSettings.city) {
                        console.debug("Widget | Settings. Update city property: " + weatherSettings.city)
                        weatherWidget.city = weatherSettings.city
                        weatherWidget.longitude = weatherSettings.longitude
                        weatherWidget.latitude = weatherSettings.latitude
                        weatherWidget.getWeather()
                    }
                }
            }
        }

        Rectangle {
            id: clockWidget
            color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
            border.color: "grey"
            width: widgetsFlow.sideLength
            height: widgetsFlow.sideLength
            visible: widgetsSettings.clockWidgetIsVisible

            // todo
            Clock {
                id: myClock
                width: 180
                height: 180
            }
        }

        Rectangle {
            id: noteWidget
            color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
            border.color: "grey"
            width: widgetsFlow.sideLength
            height: widgetsFlow.sideLength
            visible: widgetsSettings.noteWidgetIsVisible

            property var note

            Component.onCompleted: {
                var noteArr = mainView.getNotes()
                noteArr.sort(function(a, b) {
                    var sortPinned = Number(b.pinned) - Number(a.pinned)
                    if (sortPinned !== 0) {
                        return sortPinned
                    } else {
                        return b.date - a.date
                    }
                })
                if (noteArr.length > 0) {
                    noteWidget.note = noteArr[0]
                    console.debug("Widget | Note: " + noteWidget.note.content)
                }
            }

            Column {
                width: noteWidget.width
                padding: mainView.innerSpacing * 0.5

                Image {
                    id: notesIcon
                    width: 40
                    height: 40
                    source: "icons/notes@4x.png"

                    ColorOverlay {
                        anchors.fill: notesIcon
                        source: notesIcon
                        color: Universal.foreground
                    }
                }

                Button {
                    id: noteButton
                    width: noteWidget.width - mainView.innerSpacing
                    height: noteWidget.height - notesIcon.height - mainView.innerSpacing
                    flat: true
                    highlighted: false

                    contentItem: Label {
                        id: noteLabel
                        anchors.fill: noteButton
                        padding: 4
                        text: noteWidget.note !== undefined ? noteWidget.note.content : ""
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                    }

                    onClicked: {
                        console.log("Widget | Note clicked")
                        mainView.updateCollectionPage(mainView.collectionMode.Notes)
                        mainView.updateDetailPage(mainView.detailMode.Note, noteWidget.note.id, undefined,
                                                  noteWidget.note.date, noteWidget.note.content, noteWidget.note.pinned)
                    }
                }
            }
        }

        Settings {
            id: widgetsSettings
            property bool clockWidgetIsVisible: true
            property bool weatherWidgetIsVisible: true
            property bool noteWidgetIsVisible: true

            onClockWidgetIsVisibleChanged: {
                console.debug("Springborad | Clock widget visibility changed to " + clockWidgetIsVisible)
            }

            onWeatherWidgetIsVisibleChanged: {
                console.debug("Springborad | Weather widget visibility changed to " + weatherWidgetIsVisible)
            }

            onNoteWidgetIsVisibleChanged: {
                console.debug("Springborad | Note widget visibility changed to " + noteWidgetIsVisible)
            }

//            Component.onCompleted: {
//                weatherWidget.visible = weatherWidgetIsVisible
//                clockWidget.visible = clockWidgetIsVisible
//                noteWidget.visible = noteWidgetIsVisible
//            }
        }
    }

    MouseArea {
        id: shortcutMenu
        width: Screen.desktopAvailableWidth > 445 ? springBoard.menuWidth : springBoard.width
        height: dotShortcut ? mainView.innerSpacing * 4 : mainView.innerSpacing * 3
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 0 - mainView.outerSpacing

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
                console.log("Springboard | width " + parent.width, shortcutMenu.width, shortcutColumn.width)
                //shortcutBackground.visible = true
                shortcutMenu.height = shortcutColumn.height + mainView.innerSpacing * 1.5
                shortcutBackground.width = roundedShortcutMenu ? shortcutMenu.width - mainView.innerSpacing * 4 : shortcutMenu.width
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
            var leftDistance = mainView.innerSpacing * 4
            var componentWidth = Screen.width > 520 ? Screen.width * 0.6 - leftDistance : Screen.width - leftDistance
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
            visible: true
            opacity: 0.0
            width: parent.width - mainView.innerSpacing * 2
            topPadding: mainView.innerSpacing * 1.5
            rightPadding: mainView.innerSpacing
            leftPadding: mainView.innerSpacing
            bottomPadding: mainView.innerSpacing
            anchors.right: parent.right
            anchors.rightMargin: roundedShortcutMenu ? mainView.innerSpacing * 2 : 0
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

    Column {
        id: appSwitcher
        x: dotShortcut ? mainView.innerSpacing * 2 - mainView.outerSpacing : 0 - mainView.outerSpacing
        anchors.bottom: closeAppsButton.top
        anchors.bottomMargin: mainView.innerSpacing
        spacing: mainView.innerSpacing
        visible: mainView.isTablet
    }

    Button {
        id: closeAppsButton
        x: dotShortcut ? mainView.innerSpacing * 2 - mainView.outerSpacing : 0 - mainView.outerSpacing
        anchors.bottom: parent.bottom
        anchors.bottomMargin: dotShortcut ? mainView.innerSpacing * 2 : 0
        width: mainView.innerSpacing * 2
        height: mainView.innerSpacing * 2
        visible: false
        flat: true
        background: Rectangle {
            color: "transparent"
            opacity: Universal.theme === Universal.Light ? 0.4 : 0.6
            radius: width * 0.5
            border.color: Universal.foreground
        }
        contentItem: Item {
            anchors.fill: parent
            Text {
                opacity: 1.0
                anchors.centerIn: parent
                text: qsTr("x")
                color: Universal.foreground
            }
        }
        onClicked: {
            console.log("Springboard | Close all apps")
            var openApps = new Array
            for (var i = 0; i < appButtons.length; i++) {
                openApps.push(appButtons[i].app.package)
            }
            AN.SystemDispatcher.dispatch("volla.launcher.closeAppsAction", {"packages": openApps})
            appSwitcher.visible = false;
            closeAppsButton.visible = false;
        }
    }
}
