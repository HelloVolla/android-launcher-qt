import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.12
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN
import FileIO 1.0

LauncherPage {
    id: collectionPage
    anchors.fill: parent

    property var headline
    property var textInputField
    property string textInput
    property real iconSize: 64.0
    property int currentCollectionMode: 3
    property var currentCollectionModel: peopleModel
    property var threads: new Array
    property var calls: new Array
    property var threadAge: 86400 * 7 // one week in seconds
    property var messageAge: 86400 * 5 * 1000 // one day in milliseconds
    property int operationCount: 0 // number of background operations
    property int maxCalls: 50
    property int maxTextLength: 500

    property string c_TITLE:     "title"    // large main title, bold
    property string c_STITLE:    "stitle"   // small title above the main, grey
    property string c_TEXT:      "text"     // large main text, regular
    property string c_STEXT:     "stext"    // small text beyond the main text, grey
    property string c_ICON:      "icon"     // small icon at the left side
    property string c_IMAGE:     "image"    // preview image
    property string c_BADGE:     "badge"    // red dot for unread content children
    property string c_SBADGE:    "sbadge"   // red dot for unread messages
    property string c_PHONE:     "phome"    // recent phone number
    property string c_MOBILE:    "mobile"   // cell phone number
    property string c_EMAIL:     "email"    // recent email address
    property string c_ID:        "id"       // id of the contact, thread or news
    property string c_CHANNEL:   "channel"  // twitter or news channel
    property string c_TSTAMP:    "tstamp"   // timestamp to sort the list
    property string c_TYPE:      "type"     // rss or atpm feed type
    property string c_SIGNAL:    "signal"   // has a signal account

    onTextInputChanged: {
        console.log("Collections | text input changed")
        currentCollectionModel.update(textInput)
    }

    function updateCollectionPage (mode) {
        console.log("Collections | Update collection model: " + mode)

        currentCollectionMode = mode
        currentCollectionModel.clear()
        currentCollectionModel.modelArr = new Array

        switch (mode) {
            case mainView.collectionMode.People:
                headline.text = qsTr("People")
                textInputField.placeholderText = qsTr("Find people ...")
                currentCollectionModel = peopleModel
                currentCollectionModel.modelArr = new Array
                operationCount = mainView.isSignalActive ? 3 : 2
                mainView.updateSpinner(true)
                collectionPage.loadThreads({"age": threadAge})
                collectionPage.loadCalls({"age": threadAge})
                break;
            case mainView.collectionMode.Threads:
                headline.text = qsTr("Threads")
                textInputField.placeholderText = qsTr("Find thread ...")
                currentCollectionModel = threadModel
                currentCollectionModel.modelArr = new Array
                operationCount = mainView.isSignalActive ? 2 : 1
                mainView.updateSpinner(true)
                collectionPage.loadThreads({"age": threadAge})
                break;
            case mainView.collectionMode.News:
                headline.text = qsTr("News")
                textInputField.placeholderText = qsTr("Find news ...")
                currentCollectionModel = newsModel
                currentCollectionModel.modelArr = new Array
                collectionPage.threads = new Array
                collectionPage.calls = new Array
                mainView.updateSpinner(true)
                currentCollectionModel.update("")
                break;
            case mainView.collectionMode.Notes:
                headline.text = qsTr("Notes")
                textInputField.placeholderText = qsTr("Find note ...")
                currentCollectionModel = notesModel
                collectionPage.threads = new Array
                collectionPage.calls = new Array
                mainView.updateSpinner(true)
                currentCollectionModel.loadData()
                currentCollectionModel.update("")
                break;
            default:
                console.log("Collections | Unknown collection mode")
                break;
        }
    }

    function updateListModel() {
        console.log("Collections | Operation count is " + operationCount)
        operationCount = operationCount - 1
        if (operationCount < 1) {
            mainView.updateSpinner(false)
            collectionPage.currentCollectionModel.loadData()
            collectionPage.currentCollectionModel.update(collectionPage.textInput)
        }
    }

    function sortListModel() {
        var n;
        var i;
        for (n = 0; n < currentCollectionModel.count; n++) {
            for (i=n+1; i < currentCollectionModel.count; i++) {
                if (currentCollectionModel.get(n).c_TSTAMP < currentCollectionModel.get(i).c_TSTAMP) {
                    currentCollectionModel.move(i, n, 1);
                    n = 0;
                }
            }
        }
    }

    function loadThreads(filter) {
        console.log("Collections | Will load threads")
        collectionPage.threads = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.threadAction", filter)
        // load threads from further source
        // address (phone or contact), body (message), date, type
        console.debug("Collections | Signal is active: " + mainView.isSignalActive)
        if (mainView.isActiveSignal()) AN.SystemDispatcher.dispatch("volla.launcher.signalThreadsAction", filter)
    }

    function loadCalls(filter) {
        console.log("Collections | Will load calls")
        collectionPage.calls = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.callLogAction", filter)
    }

    ListView {
        id: listView
        anchors.fill: parent
        headerPositioning: mainView.backgroundOpacity === 1.0 ? ListView.PullBackHeader : ListView.InlineHeader
        clip: true

        header: Column {
            id: header
            width: parent.width
            z: 2
            Label {
                id: headerLabel
                topPadding: mainView.innerSpacing * 2
                width: parent.width - mainView.innerSpacing
                x: mainView.innerSpacing
                text: qsTr("People")
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
                background: Rectangle {
                    color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                    border.color: "transparent"
                }
                Binding {
                    target: collectionPage
                    property: "headline"
                    value: headerLabel
                }
            }
            TextField {
                id: textField
                padding: mainView.innerSpacing
                x: mainView.innerSpacing
                width: parent.width -mainView.innerSpacing * 2
                placeholderText: qsTr("Filter collections")
                color: mainView.fontColor
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.largeFontSize
                leftPadding: 0.0
                rightPadding: 0.0
                background: Rectangle {
                    color:  mainView.backgroundOpacity === 1.0 ? mainView.backgroundColor : "transparent"
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

        model: currentCollectionModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: contactBox.height

            property var selectedMenuItem: contactBox
            property bool isMenuStatus: false
            property int indexOfThisDelegate: index

            Rectangle {
                id: contactBox
                color: "transparent"
                width: parent.width
                implicitHeight: contactMenu.visible ?
                                    contactRow.height + contactMenu.height + mainView.innerSpacing
                                  : contactRow.height + mainView.innerSpacing

                Row {
                    id: contactRow
                    x: mainView.innerSpacing
                    spacing: 18.0
                    topPadding: mainView.innerSpacing / 2

                    Rectangle {
                        id: contactInicials

                        height: collectionPage.iconSize
                        width: collectionPage.iconSize
                        radius: height * 0.5
                        border.color: Universal.foreground
                        opacity: 0.9
                        color: "transparent"
                        visible: model.c_ICON === ""
                                 && (collectionPage.currentCollectionMode === mainView.collectionMode.People
                                     || collectionPage.currentCollectionMode === mainView.collectionMode.News)

                        Label {
                            text: model.c_TITLE !== undefined ? getInitials() : "?"
                            height: parent.height
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Universal.foreground
                            opacity: 0.9
                            font.pointSize: mainView.largeFontSize

                            function getInitials() {
                                const namesArray = model.c_TITLE.split(' ')
                                if (namesArray.length === 1) return `${namesArray[0].charAt(0)}`
                                else return `${namesArray[0].charAt(0)}${namesArray[namesArray.length - 1].charAt(0)}`
                            }
                        }
                    }
                    Image {
                        id: contactImage
                        source: model.c_ICON !== undefined ? model.c_ICON : ""
                        sourceSize: Qt.size(collectionPage.iconSize, collectionPage.iconSize)
                        smooth: true
                        visible: false
                        width: collectionPage.iconSize
                        height: collectionPage.iconSize
                        fillMode: collectionPage.currentCollectionMode === mainView.collectionMode.News ? Image.PreserveAspectFit
                                                                                                        : Image.PreserveAspectCrop
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
                        visible: model.c_ICON !== ""
                    }
                    Column {
                        id: contactColumn
                        spacing: 3.0

                        property real columnWidth: collectionPage.currentCollectionMode === mainView.collectionMode.Threads
                                                   || collectionPage.currentCollectionMode === mainView.collectionMode.Notes ?
                                                       contactBox.width - mainView.innerSpacing * 2 - contactRow.spacing
                                                     : contactBox.width - mainView.innerSpacing * 2 - collectionPage.iconSize  - contactRow.spacing
                        property var gradientColor: Universal.background

                        Label {
                            id: sourceLabel
                            topPadding: model.c_STITLE !== undefined ? 8.0 : 0.0
                            width: contactBox.width - mainView.innerSpacing * 2 - collectionPage.iconSize - contactRow.spacing
                            text: model.c_STITLE !== undefined ? model.c_STITLE : ""
                            font.pointSize: mainView.smallFontSize
                            color: backgroundItem.isMenuStatus ? "white" : mainView.fontColor
                            lineHeight: 1.1
                            wrapMode: Text.Wrap
                            opacity: 0.8
                            visible: model.c_STITLE !== undefined
                        }
                        Label {
                            id: titleLabel
                            topPadding: model.c_TITLE !== undefined ? 8.0 : 0.0
                            width: contactColumn.columnWidth
                            text: model.c_TITLE !== undefined ? model.c_TITLE : ""
                            font.pointSize: mainView.largeFontSize
                            font.weight: Font.Black
                            color: backgroundItem.isMenuStatus ? "white" : mainView.fontColor
                            clip: mainView.backgroundOpacity === 1.0 ? true : false
                            elide: mainView.backgroundOpacity === 1.0 ? Text.ElideNone : Text.ElideRight
                            visible: model.c_TITLE !== undefined

                            LinearGradient {
                                id: titleLabelTruncator
                                height: titleLabel.height
                                width: titleLabel.width
                                start: Qt.point(titleLabel.width - mainView.innerSpacing,0)
                                end: Qt.point(titleLabel.width,0)
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: "transparent"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: backgroundItem.isMenuStatus ? mainView.accentColor : contactColumn.gradientColor
                                    }
                                }
                                visible: mainView.backgroundOpacity === 1.0
                            }
                        }
                        Label {
                            id: textLabel
                            width: contactColumn.columnWidth
                            text: model.c_TEXT !== undefined ? model.c_TEXT : ""
                            font.pointSize: mainView.largeFontSize
                            //renderType: Text.NativeRendering
                            verticalAlignment: Text.AlignVCenter
                            lineHeight: 1.1
                            opacity: 0.9
                            color: backgroundItem.isMenuStatus ? "white" : mainView.fontColor
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            visible: model.c_TEXT !== undefined

                            // Workaround
//                            onLineLaidOut: {
//                                console.log("Collection | LINE " + line.x + ", " + line.y)
//                                line.x = 110
//                                line.y = line.y * 1.5
//                            }
                        }
                        Row {
                            id: statusRow
                            spacing: 8.0
                            Rectangle {
                                id: statusBadge
                                visible: model.c_SBADGE !== undefined ? model.c_SBADGE : false
                                width: mainView.smallFontSize * 0.6
                                height: mainView.smallFontSize * 0.6
                                y: mainView.smallFontSize * 0.3
                                radius: height * 0.5
                                color: backgroundItem.isMenuStatus ? "transparent" : mainView.accentColor
                            }
                            Label {
                                id: statusLabel
                                bottomPadding:  model.c_IMAGE !== undefined ? mainView.innerSpacing : 0.0
                                width: statusBadge.visible ?
                                           contactColumn.columnWidth - statusBadge.width - statusRow.spacing
                                         : contactColumn.columnWidth
                                text: model.c_STEXT !== undefined ? model.c_STEXT : ""
                                font.pointSize: mainView.smallFontSize
                                color: backgroundItem.isMenuStatus ? "white" : mainView.fontColor
                                clip: mainView.backgroundOpacity === 1.0 ? true : false
                                elide: mainView.backgroundOpacity === 1.0 ? Text.ElideRight : Text.ElideNone
                                opacity: 0.8
                                visible: model.c_STEXT !== undefined

                                LinearGradient {
                                    id: statusLabelTruncator
                                    height: statusLabel.height
                                    width: statusLabel.width
                                    start: Qt.point(statusLabel.width - mainView.innerSpacing,0)
                                    end: Qt.point(statusLabel.width,0)
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: "transparent"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: backgroundItem.isMenuStatus ? mainView.accentColor : contactColumn.gradientColor
                                        }
                                    }
                                    visible: mainView.backgroundOpacity === 1.0
                                }
                            }
                        }
                        Image {
                            id: newsImage
                            sourceSize.width: contactColumn.columnWidth
                            source: model.c_IMAGE !== undefined ? model.c_IMAGE : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true

                            Desaturate {
                                anchors.fill: newsImage
                                source: newsImage
                                desaturation: 1.0
                            }
                        }
                    }                    
                }
                Rectangle {
                    id: newsIconBox
                    anchors.top: contactBox.top
                    anchors.topMargin: mainView.innerSpacing * 0.5
                    anchors.left: contactBox.left
                    anchors.leftMargin: mainView.innerSpacing
                    width: collectionPage.iconSize
                    height: collectionPage.iconSize
                    color: "transparent"
                    border.color: Universal.foreground
                    opacity: 0.7
                    radius: height * 0.5
                    visible: collectionPage.currentCollectionMode === mainView.collectionMode.News
                }
                Rectangle {
                    id: notificationBadge
                    anchors.top: contactBox.top
                    anchors.topMargin: mainView.innerSpacing * 0.5
                    anchors.left: contactBox.left
                    anchors.leftMargin: mainView.innerSpacing
                    visible: model.c_BADGE !== undefined ? model.c_BADGE : false
                    width: collectionPage.iconSize * 0.25
                    height: collectionPage.iconSize * 0.25
                    radius: height * 0.5
                    color: mainView.accentColor
                }
                Column {
                    id: contactMenu
                    anchors.top: contactRow.bottom
                    topPadding: 22.0
                    bottomPadding: 8.0
                    leftPadding: mainView.innerSpacing
                    spacing: 14.0
                    visible: false

                    Label {
                        id: callLabel
                        height: mainView.mediumFontSize * 1.2
                        text: qsTr("Call")
                        font.pointSize: mainView.mediumFontSize
                        color: "white"
                        visible: model.c_PHONE !== undefined
                    }
                    Label {
                        id: messageLabel
                        height: mainView.mediumFontSize * 1.2
                        text: qsTr("Send Message")
                        font.pointSize: mainView.mediumFontSize
                        color: "white"
                        visible: model.c_MOBILE !== undefined
                    }
                    Label {
                        id: emailLabel
                        height: mainView.mediumFontSize * 1.2
                        text: qsTr("Send Email")
                        font.pointSize: mainView.mediumFontSize
                        color: "white"
                        visible: model.c_EMAIL !== undefined
                    }
                    Label {
                        id: contactLabel
                        height: mainView.mediumFontSize * 1.2
                        text: qsTr("Open Contact")
                        font.pointSize: mainView.mediumFontSize
                        color: "white"
                    }
                    Label {
                        id: openSignalContactLabel
                        height: mainView.mediumFontSize * 1.2
                        text: qsTr("Open in Signal")
                        font.pointSize: mainView.mediumFontSize
                        color: "white"
                        visible: model.c_SIGNAL !== undefined
                    }
                }
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0

                        property bool wasRunning: false

                        onRunningChanged: {
                            console.log("Collections | Running changed to " + running)
                            listView.positionViewAtIndex(backgroundItem.indexOfThisDelegate, ListView.Contain)
                            wasRunning = running
                        }
                    }
                }
            }

            onClicked: {
                console.log("Collections | List entry '" + model.c_ID + "' clicked.")
                var imPoint = mapFromItem(iconMask, 0, 0)
                if (currentCollectionMode === mainView.collectionMode.News
                        && mouseY > imPoint.y && mouseY < imPoint.y + iconMask.height
                        && mouseX > imPoint.x && mouseX < imPoint.x + iconMask.width) {
                    currentCollectionModel.executeSelection(model, mainView.actionType.ShowGroup)
                } else {
                    // todo: should be replaced by model id
                    if (statusBadge.visible) statusBadge.visible = false
                    currentCollectionModel.executeSelection(model, mainView.actionType.ShowDetails)
                }
            }
            onPressAndHold: {
                if (currentCollectionMode === mainView.collectionMode.People) {
                    contactMenu.visible = true
                    contactBox.color = mainView.accentColor
                    preventStealing = true
                    isMenuStatus = true
                }
            }
            onExited: {
                if (currentCollectionMode === mainView.collectionMode.People) {
                    contactMenu.visible = false
                    contactBox.color = "transparent"
                    preventStealing = false
                    isMenuStatus = false
                    backgroundItem.executeSelection()
                }
            }
            onMouseYChanged: {
                var plPoint = mapFromItem(callLabel, 0, 0)
                var mlPoint = mapFromItem(messageLabel, 0, 0)
                var elPoint = mapFromItem(emailLabel, 0, 0)
                var clPoint = mapFromItem(contactLabel, 0, 0)
                var sgPoint = mapFromItem(openSignalContactLabel, 0, 0)
                var selectedItem

                if (mouseY > plPoint.y && mouseY < plPoint.y + callLabel.height) {
                    selectedItem = callLabel
                } else if (mouseY > mlPoint.y && mouseY < mlPoint.y + messageLabel.height) {
                    selectedItem = messageLabel
                } else if (mouseY > elPoint.y && mouseY < elPoint.y + emailLabel.height) {
                    selectedItem = emailLabel
                } else if (mouseY > clPoint.y && mouseY < clPoint.y + contactLabel.height) {
                    selectedItem = contactLabel
                } else if (mouseY > sgPoint.y && mouseY < sgPoint.y + openSignalContactLabel.height) {
                    selectedItem = openSignalContactLabel
                } else {
                    selectedItem = contactBox
                }
                if (selectedMenuItem !== selectedItem) {
                    selectedMenuItem = selectedItem
                }
            }
            onSelectedMenuItemChanged: {
                callLabel.font.bold = selectedMenuItem === callLabel
                callLabel.font.pointSize = selectedMenuItem === callLabel ? mainView.mediumFontSize * 1.2 : mainView.mediumFontSize
                messageLabel.font.bold = selectedMenuItem === messageLabel
                messageLabel.font.pointSize = selectedMenuItem === messageLabel ? mainView.mediumFontSize * 1.2 : mainView.mediumFontSize
                emailLabel.font.bold = selectedMenuItem === emailLabel
                emailLabel.font.pointSize = selectedMenuItem === emailLabel ? mainView.mediumFontSize * 1.2 : mainView.mediumFontSize
                contactLabel.font.bold = selectedMenuItem === contactLabel
                contactLabel.font.pointSize = selectedMenuItem === contactLabel ? mainView.mediumFontSize * 1.2 : mainView.mediumFontSize
                openSignalContactLabel.font.bold = selectedMenuItem === openSignalContactLabel
                openSignalContactLabel.font.pointSize = selectedMenuItem === openSignalContactLabel ? mainView.mediumFontSize * 1.2 : mainView.mediumFontSize

                if (selectedMenuItem !== contactBox && mainView.useVibration) {
                    AN.SystemDispatcher.dispatch("volla.launcher.vibrationAction", {"duration": mainView.vibrationDuration})
                }
            }

            function executeSelection() {
                if (selectedMenuItem === callLabel) {
                    console.log("Collections | Call " + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, mainView.actionType.MakeCall)
                } else if (selectedMenuItem === messageLabel) {
                    console.log("Collections | Send message to " + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, mainView.actionType.SendSMS)
                } else if (selectedMenuItem === emailLabel) {
                    console.log("Collections | Send email to " + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, mainView.actionType.SendEmail)
                } else if (selectedMenuItem === contactLabel) {
                    console.log("Collections | Open contact of " + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, mainView.actionType.OpenContact)
                } else if (selectedMenuItem === openSignalContactLabel) {
                    console.log("Collections | Open contact in Signal" + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, mainView.actionType.OpenSignalContact)
                } else {
                    console.log("Collections | Nothing selected")
                }
            }
        }
    }

    ListModel {
        id: peopleModel

        property var modelArr: []
        property var contactThreads: new Object
        property var contactCalls: new Object

        function loadData() {
            console.log("Collections | Load data for contact collection")

            var now = new Date()

            collectionPage.threads.forEach(function (thread, index) {
                console.log("Collections | Thread: " + thread["address"] + ", " + thread["person"])
                if ((!thread["read"] || now.getTime() - thread["date"] < collectionPage.messageAge)
                        && (thread["address"].length > 0 || thread["person"] !== undefined)) {
                    if (thread["isSignal"]) contactThreads[thread["person"]] = thread
                    else contactThreads[thread["address"]] = thread
                }
            })

            collectionPage.calls.forEach(function (call, index) {
                if ((call["new"] || now.getTime() - call["date"] < collectionPage.messageAge) && call["number"] !== undefined) {
                    console.log("Collections | Call matched: " + call["number"])
                    if (contactCalls[call["number"]] === undefined) {
                        call["count"] = call["new"] ? 1 : 0
                        contactCalls[call["number"]] = call
                    } else if (call["new"] === true) {
                        contactCalls[call["number"]]["count"] += 1
                    }
                }
            })

            var contacts = mainView.getContacts().filter(checkStarredOrRecent)
            contacts.forEach(function (contact, index) {
                console.log("Collections | Matched contact: " + contact["name"])
                var cContact = {c_ID: contact["id"]}

                if (contact["name"] !== undefined) {
                    cContact.c_TITLE = contact["name"]
                } else if (contact["organization"] !== undefined) {
                    cContact.c_TITLE = contact["organization"]
                }

                if (contact["organization"] !== undefined
                        && contact["organization"].length > 0
                        && contact["name"] !== undefined) {
                    cContact.c_STEXT = contact["organization"]
                } else {
                    cContact.c_STEXT = qsTr("Private")
                }

                if (contact["icon"] !== undefined) {
                    cContact.c_ICON = "data:image/png;base64," + contact["icon"]
                } else {
                    cContact.c_ICON = ""
                    AN.SystemDispatcher.dispatch("volla.launcher.contactImageAction", {"contactId": contact["id"]})
                }

                if (contact["phone.mobile"] !== undefined) {
                    cContact.c_PHONE = contact["phone.mobile"]
                    cContact.c_MOBILE = contact["phone.mobile"]
                } else if (contact["phone.work"] !== undefined) {
                    cContact.c_PHONE = contact["phone.work"]
                } else if (contact["phone.home"] !== undefined) {
                    cContact.c_PHONE = contact["phone.home"]
                } else if (contact["phone.other"] !== undefined) {
                    cContact.c_PHONE = contact["phone.other"]
                }
                if (contact["phone.signal"] !== undefined) {
                    cContact.c_SIGNAL = contact["phone.signal"]
                }
                if (contact["email.work"] !== undefined) {
                    cContact.c_EMAIL = contact["email.work"]
                } else if (contact["email.home"] !== undefined) {
                    cContact.c_EMAIL = contact["email.home"]
                } else if (contact["email.other"] !== undefined) {
                    cContact.c_EMAIL = contact["email.other"]
                }

                var thread = contactThreads[contact["phone.mobile"]]
                if (thread === undefined) {
                    thread = contactThreads[contact["phone.other"]]
                }
                if (thread === undefined) {
                    thread = contactThreads[contact["phone.work"]]
                }

                var call = contactCalls[contact["phone.mobile"]]
                if (call === undefined) {
                    call = contactCalls[contact["phone.other"]]
                }
                if (call === undefined) {
                    call = contactCalls[contact["phone.work"]]
                }

                if ((thread !== undefined && call !== undefined && thread["date"] > call["date"])
                        || (thread !== undefined && call === undefined)) {
                    cContact.c_SBADGE = !thread["read"]
                    if (!thread["read"]) {
                        cContact.c_ITEM_ID = thread["thread_id"]
                        cContact.c_STEXT = "1 " + qsTr("New message") + " " + mainView.parseTime(Number(thread["date"]))
                    }
                } else if ((thread !== undefined && call !== undefined && thread["date"] < call["date"])
                        || (thread === undefined && call !== undefined)) {
                    cContact.c_SBADGE = call["new"]
                    // use the recent phone number
                    cContact.c_PHONE = call["number"]
                    if (call["new"] === true) {
                        var messageText = (call["count"] > 1) ? qsTr("New calls") : qsTr("New call")
                        cContact.c_STEXT = call["count"] + " " + messageText + " " + mainView.parseTime(Number(call["date"]))
                    }
                }

                modelArr.push(cContact)
            })
        }

        function checkStarredOrRecent(contact) {
            return (contact["starred"] === true
                    || (contact["phone.mobile"] in contactThreads)
                    || (contact["phone.signal"] in contactThreads)
                    || (contact["phone.other"] in contactThreads)
                    || (contact["phone.work"] in contactThreads)
                    || (contact["phone.home"] in contactThreads)
                    || (contact["name"] in contactThreads)
                    || (contact["phone.mobile"] in contactCalls)
                    || (contact["phone.signal"] in contactCalls)
                    || (contact["phone.other"] in contactCalls)
                    || (contact["phone.work"] in contactCalls)
                    || (contact["phone.home"] in contactCalls))
        }

        function updateImage(contactId, contactImage) {
            console.log("Collections | Umdate image of contact " + contactId)
            for (var i = 0; i < modelArr.length; i++) {
                var aContact = modelArr[i]
                if (aContact.c_ID === contactId) {
                    aContact.c_ICON = contactImage
                    modelArr[i] = aContact
                    break
                }
            }
            for (i = 0; i < count; i++) {
                var elem = get(i)
                if (elem.c_ID === contactId) {
                    elem.c_ICON = "data:image/png;base64," + contactImage
                    set(i, elem)
                    break
                }
            }
            for (i = 0; i < mainView.getContacts().length; i++) {
                aContact = mainView.getContacts()[i]
                if (aContact["id"] === contactId) {
                    aContact["icon"] = contactImage
                    mainView.getContacts()[i] = aContact
                    break
                }
            }
        }

        function update(text) {
            console.log("Collections | Update people model with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Collections | People model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].c_TITLE
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    // console.log("Collections | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).c_TITLE
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).c_TITLE
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
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Collections | Will append " + filteredModelItem.c_TITLE)
                    append(filteredModelDict[modelItemName])
                }
            }
        }

        function executeSelection(item, type) {
            switch (type) {
                case mainView.actionType.MakeCall:
                    util.makeCall({"number": item.c_PHONE, "intent": "call"})
                    break
                case mainView.actionType.SendSMS:
                    Qt.openUrlExternally("sms:" + item.c_MOBILE)
                    break
                case mainView.actionType.SendEmail:
                    Qt.openUrlExternally("mailto:" + item.c_EMAIL)
                    break
                case mainView.actionType.OpenContact:
                    AN.SystemDispatcher.dispatch("volla.launcher.showContactAction", {"contact_id": item.c_ID})
                    break
                case mainView.actionType.OpenSignalContact:
                    Qt.openUrlExternally("sgnl://signal.me/#p/" + item.c_SIGNAL)
                    break
                default:
                    mainView.updateConversationPage(mainView.conversationMode.Person, item.c_ID, item.c_TITLE)
            }
        }
    }

    ListModel {
        id: threadModel

        property var modelArr: []

        function loadData() {
            console.log("Collections | Load data for thread collection")

            collectionPage.threads.forEach(function (thread, index) {
                var cThread = {c_ID: thread["thread_id"], c_ICON: ""}

                function checkMatchigThread(contact) {
                    var matched = false
                    try {
                        matched = (contact["id"] !== undefined && thread["person"] !== undefined && contact["id"] === thread["person"])
                                  || (contact["phone.mobile"] !== undefined && thread["address"] !== undefined
                                      && contact["phone.mobile"].toString().endsWith(thread["address"].slice(3))
                                      && Math.abs(contact["phone.mobile"].toString().length - thread["address"].length) < 3)
                                  || (contact["phone.other"] !== undefined && thread["address"] !== undefined
                                      && contact["phone.other"].toString().endsWith(thread["address"].slice(3))
                                      && Math.abs(contact["phone.other"].toString().length - thread["address"].length) < 3)
                                  || (contact["phone.work"] !== undefined && thread["address"] !== undefined
                                      && contact["phone.work"].toString().endsWith(thread["address"].slice(3))
                                      && Math.abs(contact["phone.work"].toString().length - thread["address"].length) < 3)
                                  || (contact["phone.home"] !== undefined && thread["address"] !== undefined
                                      && contact["phone.home"].toString().endsWith(thread["address"].slice(3))
                                      && Math.abs(contact["phone.home"].toString().length - thread["address"].length) < 3)
                                  || (contact["name"] !== undefined && thread["person"] !== undefined
                                      && contact["name"].toString() === thread["person"].toString())
                    } catch (err) {
                        console.log("Collections | Error for checking contact " + contact["name"] + ": " + err.message)                        
                    }

                    return matched
                }

                var contact = mainView.getContacts().find(checkMatchigThread)

                if (contact !== undefined) {
                    cThread.c_TITLE = contact["name"]
                } else if (thread["person"] !== undefined) {
                    cThread.c_TITLE = thread["person"]
                } else if (thread["address"] !== undefined) {
                    cThread.c_TITLE = thread["address"]
                } else {
                    cThread.c_TITLE = qsTr("You")
                }

                if (thread["body"] !== undefined) {
                    if (thread["isSent"]) {
                        cThread.c_TEXT = qsTr("You") + ": " + thread["body"]
                    } else {
                        cThread.c_TEXT = thread["body"]
                    }
                }

                var kind = "SMS"

                if (thread["isMMS"]) {
                    kind = "MMS"
                    cThread.c_IMAGE = "data:image/png;base64," + thread["image"]
                } else if (thread["isSignal"]) {
                    kind = "Signal"
                }

                cThread.c_SBADGE = thread["read"] === true ? false : true
                cThread.c_STEXT = mainView.parseTime(Number(thread["date"])) + " • " + qsTr(kind)
                cThread.c_TSTAMP = Number(thread["date"])

                modelArr.push(cThread)
            })
        }

        function update (text) {
            console.log("Collections | Update model with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Collections | Model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].c_TEXT
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    //console.log("Collections | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).c_TEXT
                existingGridDict[modelItemName] = true
            }

            // Remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).c_TEXT
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Collections | Remove " + modelItemName)
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
                    console.log("Collections | Will append " + filteredModelItem.c_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }

            collectionPage.sortListModel()
        }

        function executeSelection(item, type) {
            mainView.updateConversationPage(mainView.conversationMode.Thread, item.c_ID, item.c_TITLE)
        }
    }

    ListModel {
        id: newsModel

        property var rssFeeds: new Array
        property var modelArr: new Array

        function loadData() {
            // Iterate over rss feeds to the the first item
            rssFeeds = mainView.getFeeds()
            if (rssFeeds.length > 0) {
                rssFeeds.forEach(function (rssFeed, index) {
                    if (rssFeed.activated === true) {
                        console.log("Collections | Create request for " + rssFeed.id)
                        var doc = new XMLHttpRequest();
                        doc.onreadystatechange = function() {
                            if (doc.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                                console.log("Collections | Received header status of " + rssFeed.name + ": " + doc.status);
                                if (doc.status >= 400) {
                                    mainView.updateSpinner(false)
                                    mainView.showToast(qsTr("Could not load RSS feed: ") + rssFeed.name)
                                }
                            } else if (doc.readyState === XMLHttpRequest.DONE) {
                                var cNews = {c_CHANNEL: rssFeed.id}

                                if (rssFeed.icon !== undefined) {
                                    cNews.c_ICON = rssFeed.icon
                                } else {
                                    cNews.c_ICON = ""
                                }

                                console.log("Collections | XML of " + rssFeed.name + ": " + doc.responseXML)

                                if (doc.responseXML !== null) {
                                    var rss = doc.responseXML.documentElement
                                    var channel
                                    if (rss.nodeName === "feed") {
                                        channel = rss
                                    } else {
                                        for (var i = 0; i < rss.childNodes.length; ++i) {
                                            if (rss.childNodes[i].nodeName === "channel" || rss.childNodes[i].nodeName === "feed") {
                                                channel = rss.childNodes[i]
                                                break
                                            }
                                        }
                                    }
                                    if (channel === undefined) {
                                        console.log("Collection | Missing rss channel")
                                        mainView.showToast(qsTr("Invalid RSS feed: ") + rssFeed.name)
                                        return
                                    }

                                    var feedItem
                                    for (i = 0; i < channel.childNodes.length; ++i) {
                                        if (channel.childNodes[i].nodeName === "title") {
                                            var childNode = channel.childNodes[i]
                                            var textNode = childNode.firstChild
                                            cNews.c_STITLE = textNode.nodeValue + " • Feed"
                                        }
                                        if (channel.childNodes[i].nodeName === "item" || channel.childNodes[i].nodeName === "entry") {
                                            feedItem = channel.childNodes[i]
                                            cNews.c_TYPE = channel.childNodes[i].nodeName === "item" ? mainView.feedMode.RSS
                                                                                                     : mainView.feedMode.Atom
                                            break
                                        }
                                    }
                                    if (feedItem === undefined) {
                                        console.log("Collection | Missing rss feed item")
                                        mainView.showToast(qsTr("Missing RSS item: ") + rssFeed.id)
                                        return
                                    }
                                    for (i = 0; i < feedItem.childNodes.length; ++i) {
                                        childNode = feedItem.childNodes[i]
                                        textNode = childNode.firstChild

                                        if (childNode.nodeName === "title") {
                                            if (textNode.nodeValue.length > maxTextLength) {
                                                cNews.c_TEXT = textNode.nodeValue.slice(0, maxTextLength) + "…"
                                            } else {
                                                cNews.c_TEXT = textNode.nodeValue
                                            }
                                        }
                                        else if (childNode.nodeName === "pubDate" || childNode.nodeName === "published") {
                                            var date = new Date(textNode.nodeValue)
                                            cNews.c_TSTAMP = date.valueOf()
                                            cNews.c_STEXT = mainView.parseTime(date.valueOf())
                                        }
                                        else if (childNode.nodeName === "link") {
                                            if (textNode && textNode.nodeValue !== undefined) {
                                                cNews.c_ID = textNode.nodeValue
                                            } else {
                                                var isImage = false
                                                for (var ii = 0; ii < childNode.attributes.length; ++ii) {
                                                    var attribute = childNode.attributes[ii]
                                                    if (attribute.name === "rel" && attribute.value === "enclosure") {
                                                        isImage = true
                                                    } else if (attribute.name === "href") {
                                                        if (isImage) {
                                                            console.log("MainView | Image: " + attribute.value)
                                                            cNews.c_IMAGE = attribute.value
                                                            break
                                                        } else {
                                                            console.log("MainView | Link: " + attribute.value)
                                                            cNews.c_ID = attribute.value
                                                            break
                                                        }
                                                    }
                                                }
                                            }
                                            if (rssFeed["recent"] === undefined || rssFeed["recent"] !== cNews.c_ID) {
                                                cNews.c_BADGE = true
                                            }
                                        }
                                        else if (childNode.nodeName === "content" || childNode.nodeName === "thumbnail" || childNode.nodeName === "enclosure") {
                                            for (ii = 0; ii < childNode.attributes.length; ++ii) {
                                                attribute = childNode.attributes[ii]
                                                if (attribute.name === "url") {
                                                    console.log("Collections | Image: " + attribute.value)
                                                    cNews.c_IMAGE = attribute.value
                                                    break
                                                }
                                            }
                                        } 
                                    }
                                } else if (doc.responseText !== null) {
                                    console.log("Collections | Use fall back for " + rssFeed.name)
                                    cNews.c_STITLE = rssFeed.name + " • Feed"

                                    var xmlString = doc.responseText
                                    var startTag = "<item>"
                                    var closeTag = "</item>"
                                    var start = xmlString.indexOf(startTag, 0) + startTag.length
                                    var end = xmlString.indexOf(closeTag, 0)
                                    xmlString = xmlString.slice(start, end)

                                    console.log("Collections | Start and end of item: " + start + ", " + end)
                                    console.log("Collection | Item: " + xmlString)

                                    startTag = "<title><![CDATA["
                                    closeTag = "]]></title>"
                                    start = xmlString.indexOf(startTag) + startTag.length
                                    end = xmlString.indexOf(closeTag)
                                    if (start === -1) {
                                        startTag = "<title>"
                                        closeTag = "</title>"
                                        start = xmlString.indexOf(startTag) + startTag.length
                                        end = xmlString.indexOf(closeTag)
                                    }
                                    cNews.c_TEXT = xmlString.slice(start, end)

                                    console.log("Collections | Start and end of item: " + start + ", " + end)
                                    console.log("Collection | Title: " + xmlString.slice(start, end))

                                    startTag = "<pubDate>"
                                    closeTag = "</pubDate>"
                                    start = xmlString.indexOf(startTag) + startTag.length
                                    end = xmlString.indexOf(closeTag)
                                    date = new Date(xmlString.slice(start, end))
                                    cNews.c_TSTAMP = date.valueOf()
                                    cNews.c_STEXT = mainView.parseTime(date.valueOf())

                                    startTag = "<link>"
                                    closeTag = "</link>"
                                    start = xmlString.indexOf(startTag) + startTag.length
                                    end = xmlString.indexOf(closeTag)
                                    cNews.c_ID = xmlString.slice(start, end)

                                    if (rssFeed["recent"] === undefined || rssFeed["recent"] !== cNews.c_ID) {
                                        cNews.c_BADGE = true
                                    }
                                }

                                modelArr.push(cNews)
                                mainView.updateSpinner(false)
                                update(collectionPage.textInput)
                            }
                        }
                        doc.open("GET", rssFeed.id)
                        doc.send()
                    }
                })
            } else {
                mainView.updateSpinner(false)
            }
        }

        function update (text) {
            console.log("Collections | Update model with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Collections | Model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].c_TEXT
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    //console.log("Collections | Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).c_TEXT
                existingGridDict[modelItemName] = true
            }

            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).c_TEXT
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
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Collections | Will append " + filteredModelItem.c_STITLE)
                    append(filteredModelDict[modelItemName])
                }
            }

            sortModel()
        }

        function sortModel() {
            var n;
            var i;
            for (n = 0; n < count; n++) {
                for (i=n+1; i < count; i++) {
                    if (get(n).c_TSTAMP < get(i).c_TSTAMP) {
                        move(i, n, 1);
                        n = 0;
                    }
                }
            }
        }

        function executeSelection(item, type) {
            if (type === mainView.actionType.ShowGroup) {
                var n = item.c_STITLE.indexOf("•") - 1
                var author = item.c_STITLE.substring(0, n)
                mainView.updateNewsPage(item.c_TYPE, item.c_CHANNEL, author, item.c_ICON)
            } else {
                n = item.c_STITLE.indexOf("•") - 1
                author = item.c_STITLE.substring(0, n)
                mainView.updateDetailPage(mainView.detailMode.Web, item.c_ID, author, item.c_STEXT, item.c_TEXT)
                mainView.updateRecentNews(item.c_CHANNEL, item.c_ID)
            }
        }
    }

    ListModel {
        id: notesModel

        property var modelArr: new Array

        function loadData() {
            var rawNotes = mainView.getNotes()
            console.log("Collections | Did load " + rawNotes.length + " raw notes")
            for (var i = 0; i < rawNotes.length; i++) {
                var rawNote = rawNotes[i]
                var note = {"c_ID": rawNote["id"]}
                note.c_STEXT = mainView.parseTime(rawNote.date)
                note.c_TSTAMP = rawNote.date
                var title = rawNote.content.replace(/($)/gm, "\n")
                var titleEnd = title.indexOf("\n")
                note.c_TEXT = titleEnd > 0 && titleEnd < mainView.maxTitleLength ?
                                title.slice(0, titleEnd) : titleEnd > mainView.maxTitleLength ?
                                title.slice(0, mainView.maxTitleLength) + "..." : title
                note.c_CONTENT = rawNote.content
                note.c_ICON = ""
                note.c_SBADGE = rawNote.pinned
                modelArr.push(note)
            }
            mainView.updateSpinner(false)
        }

        function update (text) {
            console.log("Collections | Update model with text input: " + text)

            if (modelArr.length === 0) {
                loadData()
            }

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Collections | Model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemID = filteredModelItem.c_ID
                var modelItemConent = filteredModelItem.c_CONTENT
                if (text.length === 0 || modelItemConent.toLowerCase().includes(text.toLowerCase())) {
                    filteredModelDict[modelItemID] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemID = get(i).c_ID
                existingGridDict[modelItemID] = true
            }

            // Remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemID = get(i).c_ID
                found = filteredModelDict.hasOwnProperty(modelItemID)
                if (!found) {
                    console.log("Collections | Remove note " + modelItemID)
                    remove(i)
                } else {
                    i++
                }
            }

            // Add new items
            for (modelItemID in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemID)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemID]
                    console.log("Collections | Will append note " + filteredModelItem.c_ID)
                    append(filteredModelDict[modelItemID])
                }
            }

            sortModel()
        }

        function sortModel() {
            var n;
            var i;
            for (n = 0; n < count; n++) {
                for (i=n+1; i < count; i++) {
                    if ((!get(n).c_SBADGE && get(i).c_SBADGE) || get(n).c_TSTAMP < get(i).c_TSTAMP) {
                        move(i, n, 1);
                        n = 0;
                    }
                }
            }
        }

        function executeSelection(item, type) {
            mainView.updateDetailPage(mainView.detailMode.Note, item.c_ID, undefined, item.c_STEXT, item.c_CONTENT, item.c_SBADGE)
        }
    }

    Button {
        id: addNoteButton
        flat: true
        visible: currentCollectionMode === mainView.collectionMode.Notes
        z: 2
        width: mainView.innerSpacing * 2
        height: mainView.innerSpacing * 2

        anchors.right: parent.right
        anchors.rightMargin: mainView.innerSpacing * 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: mainView.innerSpacing * 2

        background: Rectangle {
            id: backgroundRec
            color: mainView.fontColor
            opacity: 0.2
            border.color: "transparent"
            radius: mainView.innerSpacing
        }

        icon.source: Qt.resolvedUrl("icons/notes@4x.png")

        onPressed: {
            backgroundRec.color = mainView.accentColor
            opacity: 1.0
        }

        onClicked: {
            backgroundRec.color = mainView.fontColor
            opacity: 0.2
            var d = new Date
            mainView.updateDetailPage(mainView.detailMode.Note, d.valueOf(), undefined, mainView.parseTime(d), new String, false)
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.threadResponse") {
                console.log("Collections | onDispatched: " + type)
                if (currentCollectionMode === mainView.collectionMode.People
                        || currentCollectionMode === mainView.collectionMode.Threads) {
                    collectionPage.threads = collectionPage.threads.concat(message["threads"])
                    collectionPage.updateListModel()
                }
            } else if (type === "volla.launcher.signalThreadsResponse") {
                console.log("Collections | onDispatched: " + type)
                if (currentCollectionMode === mainView.collectionMode.People
                        || currentCollectionMode === mainView.collectionMode.Threads) {
                    message["messages"].forEach(function (aThread, index) {
                        aThread["isSignal"] = true
                        //aThread["read"] = true // workaround for allways false negative
//                        for (const [aThreadKey, aThreadValue] of Object.entries(aThread)) {
//                            console.log("Collections | * " + aThreadKey + ": " + aThreadValue)
//                        }
                    })
                    collectionPage.threads = collectionPage.threads.concat(message["messages"])
                    collectionPage.updateListModel()
                }
            } else if (type === "volla.launcher.callLogResponse") {
                console.log("Collections | onDispatched: " + type)
                if (currentCollectionMode === mainView.collectionMode.People
                        || currentCollectionMode === mainView.collectionMode.Threads) {
                    collectionPage.calls = collectionPage.calls.concat(message["calls"])
                    collectionPage.updateListModel()
                }
            } else if (type === "volla.launcher.contactImageResponse") {
                console.log("Collections | onDispatched: " + type)
                if (message["hasIcon"]) {
                    peopleModel.updateImage(message["contactId"], message["icon"])
                }
            }
        }
    }

    // @disable-check M300
    AN.Util {
        id: util
    }

    FileIO {
        id: threadsCache
        source: "threads.json"
        onError: {
            console.log("Collections | Thread cache error: " + msg)
        }
    }

    FileIO {
        id: callsCache
        source: "calls.json"
        onError: {
            console.log("Collections | Calls cache error: " + msg)
        }
    }
}
