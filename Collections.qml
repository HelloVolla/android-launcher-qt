import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.13
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

Page {
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
    property var threadAge: 84000 * 10 // one day in seconds
    property int maxCalls: 50

    property string c_TITLE:     "title"    // large main title, bold
    property string c_STITLE:    "stitle"   // small title above the main, grey
    property string c_TEXT:      "text"     // large main text, regular
    property string c_STEXT:     "stext"    // small text beyond the main text, grey
    property string c_ICON:      "icon"     // small icon at the left side
    property string c_IMAGE:     "image"    // preview image
    property string c_BADGE:     "badge"    // red dot for unread content children
    property string c_SBADGE:    "sbadge"   // red dot for unread messages
    property string c_PHONE:     "phome"    // recent phone number
    property string c_IS_MOBILE: "mobile"   // true if phone number is for a cell phone
    property string c_EMAIL:     "email"    // recent email address
    property string c_ID:        "id"       // id of the contact, thread or news

    onTextInputChanged: {
        console.log("Collections | text input changed")
        currentCollectionModel.update(textInput)
    }

    Component.onCompleted: {  
        textInput.text = ""
        currentCollectionModel.update("")
    }

    function updateCollectionMode (mode) {
        console.log("Collections | Update collection model: " + mode)

        if (mode !== currentCollectionMode) {
            currentCollectionMode = mode
            currentCollectionModel.clear()
            currentCollectionModel.modelArr = new Array

            switch (mode) {
                case swipeView.collectionMode.People:
                    headline.text = qsTr("People")
                    textInputField.placeholderText = "Find poeple ..."
                    currentCollectionModel = peopleModel
                    collectionPage.loadThreads({})
                    collectionPage.loadCalls({"count": maxCalls})
                    break;
                case swipeView.collectionMode.Threads:
                    headline.text = qsTr("Threads")
                    textInputField.placeholderText = "Find thread ..."
                    currentCollectionModel = threadModel
                    collectionPage.loadThreads({})
                    break;
                case swipeView.collectionMode.News:
                    headline.text = qsTr("News")
                    textInputField.placeholderText = "Find news ..."
                    currentCollectionModel = newsModel
                    collectionPage.threads = new Array
                    break;
                default:
                    console.log("Collections | Unknown collection mode")
                    break;
            }
        }
    }

    function loadThreads(filter) {
        console.log("Collections | Will load threads")
        // Todo: Update threads
        collectionPage.threads = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.threadAction", filter)
    }

    function loadCalls(filter) {
        console.log("Collections | Will load calls")
        collectionPage.calls = new Array
        AN.SystemDispatcher.dispatch("volla.launcher.callLogAction", filter)
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
                    text: qsTr("People")
                    font.pointSize: swipeView.headerFontSize
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
                    font.pointSize: swipeView.largeFontSize
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
                implicitHeight: contactMenu.visible ?
                                    contactRow.height + contactMenu.height + swipeView.innerSpacing
                                  : contactRow.height + swipeView.innerSpacing

                Row {
                    id: contactRow
                    x: swipeView.innerSpacing
                    spacing: 18.0
                    topPadding: swipeView.innerSpacing / 2

                    // todo: handle no image
                    Rectangle {
                        id: contactInicials

                        height: collectionPage.iconSize
                        width: collectionPage.iconSize
                        radius: height * 0.5
                        border.color: Universal.foreground
                        opacity: 0.9
                        color: "transparent"
                        visible: model.c_ICON === undefined && collectionPage.currentCollectionMode === swipeView.collectionMode.People

                        Label {
                            text: getInitials()
                            height: parent.height
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Universal.foreground
                            opacity: 0.9
                            font.pointSize: swipeView.largeFontSize

                            function getInitials() {
                                const namesArray = model.c_TITLE.split(' ');
                                if (namesArray.length === 1) return `${namesArray[0].charAt(0)}`;
                                else return `${namesArray[0].charAt(0)}${namesArray[namesArray.length - 1].charAt(0)}`;
                            }
                        }
                    }
                    Image {
                        id: contactImage
                        source: model.c_ICON !== undefined ? model.c_ICON : ""
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
                        visible: model.c_ICON !== undefined
                    }
                    Column {
                        id: contactColumn
                        spacing: 3.0

                        property real columnWidth: collectionPage.currentCollectionMode === swipeView.collectionMode.Threads ?
                                                       contactBox.width - swipeView.innerSpacing * 2 - contactRow.spacing
                                                     : contactBox.width - swipeView.innerSpacing * 2 - collectionPage.iconSize  - contactRow.spacing

                        Label {
                            id: sourceLabel
                            topPadding: model.c_STITLE !== undefined ? 8.0 : 0.0
                            width: contactBox.width - swipeView.innerSpacing * 2 - collectionPage.iconSize - contactRow.spacing
                            text: model.c_STITLE !== undefined ? model.c_STITLE : ""
                            font.pointSize: swipeView.smallFontSize
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
                            font.pointSize: swipeView.largeFontSize
                            font.weight: Font.Black
                            visible: model.c_TITLE !== undefined

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
                            width: contactColumn.columnWidth
                            text: model.c_TEXT !== undefined ? model.c_TEXT : ""
                            font.pointSize: swipeView.largeFontSize
                            lineHeight: 1.1
                            opacity: 0.9
                            wrapMode: Text.WordWrap
                            visible: model.c_TEXT !== undefined
                        }
                        Row {
                            id: statusRow
                            spacing: 8.0
                            Rectangle {
                                id: statusBadge
                                visible: model.c_SBADGE !== undefined ? model.c_SBADGE : false
                                width: swipeView.smallFontSize * 0.6
                                height: swipeView.smallFontSize * 0.6
                                y: swipeView.smallFontSize * 0.3
                                radius: height * 0.5
                                color: backgroundItem.isMenuStatus ? Universal.background : Universal.accent
                            }
                            Label {
                                id: statusLabel
                                bottomPadding:  model.c_IMAGE !== undefined ? swipeView.innerSpacing : 0.0
                                width: statusBadge.visible ?
                                           contactColumn.columnWidth - statusBadge.width - statusRow.spacing
                                         : contactColumn.columnWidth
                                text: model.c_STEXT !== undefined ? model.c_STEXT : ""
                                font.pointSize: swipeView.smallFontSize
                                clip: true
                                opacity: 0.8
                                visible: model.c_STEXT !== undefined

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
                            width: contactColumn.columnWidth
                            source: model.c_IMAGE !== undefined ? model.c_IMAGE : ""
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
                    visible: model.c_BADGE !== undefined ? model.c_BADGE : false
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
                        height: swipeView.mediumFontSize * 1.2
                        text: qsTr("Call")
                        font.pointSize: swipeView.mediumFontSize
                        visible: model.c_PHONE !== undefined
                    }
                    Label {
                        id: messageLabel
                        height: swipeView.mediumFontSize * 1.2
                        text: qsTr("Send Message")
                        font.pointSize: swipeView.mediumFontSize
                        visible: model.c_PHONE !== undefined && model.c_IS_MOBILE
                    }
                    Label {
                        id: emailLabel
                        height: swipeView.mediumFontSize * 1.2
                        text: qsTr("Send Email")
                        font.pointSize: swipeView.mediumFontSize
                        visible: model.c_EMAIL !== undefined
                    }
                }
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }
            }

            onClicked: {
                console.log("Collections | List entry '" + model.c_TITLE + "' clicked.")
                var imPoint = mapFromItem(iconMask, 0, 0)
                if (currentCollectionMode === swipeView.collectionMode.News
                        && mouseY > imPoint.y && mouseY < imPoint.y + iconMask.height
                        && mouseX > imPoint.x && mouseX < imPoint.x + iconMask.width) {
                    currentCollectionModel.executeSelection(model, swipeView.actionType.ShowGroup)
                } else {
                    // todo: should be replaced by model id
                    currentCollectionModel.executeSelection(model, swipeView.actionType.ShowDetails)
                }
            }
            onPressAndHold: {
                if (currentCollectionMode === swipeView.collectionMode.People) {
                    contactMenu.visible = true
                    contactBox.color = Universal.accent
                    preventStealing = true
                    isMenuStatus = true
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
                callLabel.font.pointSize = selectedMenuItem === callLabel ? swipeView.mediumFontSize * 1.2 : swipeView.mediumFontSize
                messageLabel.font.bold = selectedMenuItem === messageLabel
                messageLabel.font.pointSize = selectedMenuItem === messageLabel ? swipeView.mediumFontSize * 1.2 : swipeView.mediumFontSize
                emailLabel.font.bold = selectedMenuItem === emailLabel
                emailLabel.font.pointSize = selectedMenuItem === emailLabel ? swipeView.mediumFontSize * 1.2 : swipeView.mediumFontSize
            }

            function executeSelection() {
                if (selectedMenuItem === callLabel) {
                    console.log("Collections | Call " + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, swipeView.actionType.MakeCall)
                } else if (selectedMenuItem === messageLabel) {
                    console.log("Collections | Send message to " + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, swipeView.actionType.SendSMS)
                } else if (selectedMenuItem === emailLabel) {
                    console.log("Collections | Send email to " + model.c_TITLE)
                    currentCollectionModel.executeSelection(model, swipeView.actionType.SendEmail)
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

            collectionPage.threads.forEach(function (thread, index) {
                if ((!thread["read"] || Date.now() - thread["date"] < collectionPage.threadAge) && thread["address"] !== undefined) {
                    contactThreads[thread["address"]] = thread
                }
            })

            collectionPage.calls.forEach(function (call, index) {
                if ((call["new"] || Date.now() - call["date"] < collectionPage.threadAge) && call["number"] !== undefined) {
                    if (contactCalls[call["number"]] === undefined) {
                        call["count"] = call["new"] ? 1 : 0
                        contactCalls[call["number"]] = call
                    } else if (call["new"] === true) {
                        contactCalls[call["number"]]["count"] += 1
                    }
                }
            })

            var contacts = swipeView.contacts.filter(checkStarredOrRecent)
            contacts.forEach(function (contact, index) {
                console.log("Collections | Matched contact: " + contact["name"])
                var cContact = {c_ID: contact["id"]}

                if (contact["name"] !== undefined) {
                    cContact.c_TITLE = contact["name"]
                } else if (contact["organization"] !== undefined) {
                    cContact.c_TITLE = contact["organization"]
                }

                if (contact["organization"] !== undefined && contact["name"] !== undefined) {
                    cContact.c_STEXT = contact["organization"]
                } else {
                    cContact.c_STEXT = qsTr("Private")
                }

                if (contact["icon"] !== undefined) {
                    cContact.c_ICON = "data:image/png;base64," + contact["icon"]
                }

                if (contact["phone.mobile"] !== undefined) {
                    cContact.c_PHONE = contact["phone.mobile"]
                    cContact.c_IS_MOBILE = true
                } else if (contact["phone.other"] !== undefined) {
                    cContact.c_PHONE = contact["phone.other"]
                    cContact.c_IS_MOBILE = false
                } else if (contact["phone.home"] !== undefined) {
                    cContact.c_PHONE = contact["phone.home"]
                    cContact.c_IS_MOBILE = false
                } else if (contact["phone.work"] !== undefined) {
                    cContact.c_PHONE = contact["phone.work"]
                    cContact.c_IS_MOBILE = false
                }

                if (contact["email.work"] !== undefined) {
                    cContact.c_EMAIL = contact["email.work"]
                } else if (contact["email.home"] !== undefined) {
                    cContact.c_EMAIL = contact["email.home"]
                } else if (contact["email.other"] !== undefined) {
                    cContact.c_EMAIL = contact["email.other"]
                } else if (contact["email.mobile"] !== undefined) {
                    cContact.c_EMAIL = contact["email.mobile"]
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
                        cContact.c_STEXT = "1 " + qsTr("New message") + " " + collectionPage.parseTime(thread["date"])
                    }
                } else if ((thread !== undefined && call !== undefined && thread["date"] < call["date"])
                        || (thread === undefined && call !== undefined)) {
                    cContact.c_SBADGE = call["new"]
                    if (call["new"] === true) {
                        var messageText = (call["count"] > 1) ? qsTr("New calls") : qsTr("New call")
                        cContact.c_STEXT = call["count"] + " " + messageText + " " + collectionPage.parseTime(call["date"])
                    }
                }

                modelArr.push(cContact)
            })
        }

        function checkStarredOrRecent(contact) {
            return (contact["starred"] === true
                    || (contact["phone.mobile"] in contactThreads)
                    || (contact["phone.other"] in contactThreads)
                    || (contact["phone.work"] in contactThreads)
                    || (contact["phone.home"] in contactThreads)
                    || (contact["phone.mobile"] in contactCalls)
                    || (contact["phone.other"] in contactCalls)
                    || (contact["phone.work"] in contactCalls)
                    || (contact["phone.home"] in contactCalls))
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
                    console.log("Collections | Add " + modelItemName + " to filtered items")
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
                case swipeView.actionType.MakeCall:
                    Qt.openUrlExternally("tel:" + item.c_PHONE)
                    break
                case swipeView.actionType.SendSMS:
                    Qt.openUrlExternally("sms:" + item.c_PHONE)
                    break
                case swipeView.actionType.SendEmail:
                    Qt.openUrlExternally("mailto:" + item.c_EMAIL)
                    break
                default:
                    // Todo: Create dynamic detail page
                    swipeView.updateConversationPage(swipeView.conversationMode.Person, item.c_ID, item.c_TITLE)
            }
        }
    }

    ListModel {
        id: threadModel

        property var modelArr: []

        function loadData() {
            console.log("Collections | Load data for thread collection")

            collectionPage.threads.forEach(function (thread, index) {
                var cThread = {c_ID: thread["thread_id"]}

                function checkMatchigThread(contact) {
                    return (contact["id"] === thread["person"]
                            || (contact["phone.mobile"] === thread["address"])
                            || (contact["phone.other"] === thread["address"])
                            || (contact["phone.work"] === thread["address"])
                            || (contact["phone.home"] === thread["address"]))
                }

                var contact = swipeView.contacts.find(checkMatchigThread)

                if (contact !== undefined) {
                    cThread.c_TITLE = contact["name"]
                } else {
                    cThread.c_TITLE = thread["address"]
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
                }

                cThread.c_STEXT = collectionPage.parseTime(thread["date"]) + " • " + qsTr(kind)

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

            console.log("Collections | Model has " + modelArr.length + "elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].c_TEXT
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Collections | Add " + modelItemName + " to filtered items")
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
        }

        function executeSelection(item, typ) {
            swipeView.updateConversationPage(swipeView.conversationMode.Thread, item.c_ID, item.c_TITLE)
        }
    }

    ListModel {
        id: newsModel

        property var modelArr: [{c_STITLE: "The New York Times • Feed", c_TEXT: "What Makes People Charismatic and How You Can Be, Too", c_STEXT: "14 Min ago", c_ICON: "/images/news-ny-times.png", c_BADGE: true},
                                {c_STITLE: "Ben Rogers\n@brogers • Twitter", c_TEXT: "Impressive view from the coars of the lake Juojärvi in Finnland :)", c_STEXT: "1h ago", c_ICON: "/images/news-ben-rogers.jpg", c_IMAGE: "/images/news-image.png", c_BADGE: false}]

        function loadData() {

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
                    console.log("Collections | Add " + modelItemName + " to filtered items")
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
                    console.log("Collections | Will append " + filteredModelItem.c_TEXT)
                    append(filteredModelDict[modelItemName])
                }
            }
        }

        function executeSelection(item, type) {
            if (type === swipeView.actionType.ShowGroup) {
                console.log("Collections | Group view not implemented yet")
            } else {
                swipeView.updateDetailPage("/images/newsDetail01.png", "", "")
            }
        }
    }

    AN.Util {
        id: util

        onSmsFetched: {
            console.log("Collections | " + smsMessagesCount + "SMS fetched")
            smsMessages.forEach(function (smsMessage, index) {
                for (const [messageKey, messageValue] of Object.entries(smsMessage)) {
                    console.log("Collections | * " + messageKey + ": " + messageValue)
                }
            })
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
            if (type === "volla.launcher.threadResponse") {
                console.log("Collections | onDispatched: " + type)
                collectionPage.threads = message["threads"]
                message["threads"].forEach(function (thread, index) {
                    for (const [threadKey, threadValue] of Object.entries(thread)) {
                        console.log("Collections | * " + threadKey + ": " + threadValue)
                    }
                })
                collectionPage.currentCollectionModel.loadData()
                collectionPage.currentCollectionModel.update(collectionPage.textInput)
            } else if (type === "volla.launcher.callLogResponse") {
                console.log("Collections | onDispatched: " + type)
                collectionPage.calls = message["calls"]
                message["calls"].forEach(function (call, index) {
                    for (const [callKey, callValue] of Object.entries(call)) {
                        console.log("Collections | * " + callKey + ": " + callValue)
                    }
                })
                collectionPage.currentCollectionModel.loadData()
                collectionPage.currentCollectionModel.update(collectionPage.textInput)
            }
        }
    }
}
