import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.XmlListModel 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN
import FileIO 1.0

Page {
    id: appLauncher
    anchors.fill: parent

    property string textInput
    property real labelPointSize: 16
    property var iconMap: {
        "com.simplemobiletools.dialer": "/icons/dial-phone@4x.png",
        "com.simplemobiletools.smsmessenger": "/icons/message@4x.png",
        "com.android.mms" : "/icons/message@4x.png",
        "com.android.messaging": "/icons/message@4x.png",
        "com.google.android.apps.messaging" : "/icons/message@4x.png",
        "net.osmand.plus": "/icons/route-directions-map@4x.png",
        "com.mediatek.camera": "/icons/camera@4x.png",
        "com.simplemobiletools.gallery.pro": "/icons/photo-gallery@4x.png",
        "com.simplemobiletools.contacts.pro": "/icons/people-contacts-agenda@4x.png",
        "com.simplemobiletools.clock": "/icons/clock@4x.png",
        "com.android.settings": "/icons/settings@4x.png",
        "com.simplemobiletools.calendar.pro": "/icons/calendar@4x.png",
        "com.simplemobiletools.filemanager.pro": "/icons/folder@4x.png",
        "org.telegram.messenger": "/icons/telegram@4x.png",
        "com.android.email": "/icons/email@4x.png",
        "com.google.android.gm": "/icons/email@4x.png",
        "com.Slack": "/icons/slack@4x.png",
        "com.simplemobiletools.notes.pro": "/icons/notes@4x.png",
        "org.mozilla.fennec_fdroid": "/icons/browser@4x.png",
        "com.maxfour.music": "/icons/music@4x.png",
        "com.instagram.android": "/icons/instagram@4x.png",
        "com.github.yeriomin.yalpstore": "/icons/yalp-store@4x.png",
        "com.aurora.store": "/icons/aurora-store-line@4x.png",
        "com.amazon.mShop.android.shopping": "/icons/amazon@4x.png",
        "de.hafas.android.db": "/icons/db-navigator@4x.png",
        "com.dropbox.android": "/icons/dropbox@4x.png",
        "org.fdroid.fdroid": "/icons/f-droid@4x.png",
        "com.facebook.katana": "/icons/facebook@4x.png",
        "de.gmx.mobile.android.mail": "/icons/gmx@4x.png",
        "hideme.android.vpn.noPlayStore": "/icons/hide-me@4x.png",
        "com.linkedin.android": "/icons/linkedin@4x.png",
        "com.nextcloud.client": "/icons/nextcloud@4x.png",
        "com.paypal.android.p2pmobile": "/icons/paypal@4x.png",
        "com.skype.raider": "/icons/skype@4x.png",
        "com.spotify.music": "/icons/spotify@4x.png",
        "de.tutao.tutanota": "/icons/tutanota@4x.png",
        "com.volla.launcher": "/icons/volla-settings@4x.png",
        "de.web.mobile.android.mail": "/icons/web-de@4x.png",
        "com.wetter.androidclient": "/icons/wetter-com@4x.png",
        "com.whatsapp": "/icons/whats-app@4x.png",
        "com.android.fmradio": "/icons/radio@4x_104x104px.png",
        "at.bitfire.davdroid": "/icons/sync@4x_104x104px.png",
        "org.thoughtcrime.securesms": "/icons/signal@4x_104x104px.png",
        "de.baumann.weather": "/icons/weather@4x_104x104px.png",
        "com.simplemobiletools.calculator": "/icons/calculator@4x_104x104px.png",
        "com.android.calculator2": "/icons/calculator@4x_104x104px.png",
        "eu.siacs.conversations": "/icons/xmpp@4x_104x104px.png"
    }
    property var labelMap: {
        "org.mozilla.fennec_fdroid": "Browser",
        "com.google.android.gm" : "Mail",
        "at.bitfire.davdroid": "Sync",
        "hideme.android.vpn.noPlayStore": "VPN",
        "com.simplemobiletools.filemanager.pro": "Files",
        "com.aurora.store": "Store",
        "net.osmand.plus": "Maps",
        "com.volla.launcher": "Settings",
        "com.simplemobiletools.smsmessenger": "Messages",
        "com.android.fmradio" : "Radio",
        "de.baumann.weather": "Wetter",
    }
    property bool unreadMessages: false
    property bool newCalls: false
    property int appCount: 0

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    onTextInputChanged: {
        console.log("text input changed")
        gridModel.update(textInput)
        //xmlModel.update(textInput)
    }

    function updateAppLauncher(useColoredAppIcons) {
        settings.sync()
        gridView.desaturation = useColoredAppIcons ? 0.0 : 1.0
        gridView.forceLayout()
    }

    function updateNotifications() {
        AN.SystemDispatcher.dispatch("volla.launcher.callLogAction", {"is_read": 0})
        AN.SystemDispatcher.dispatch("volla.launcher.threadsCountAction", {"read": 0})
    }

    function getCurrentApps() {
        return gridModel.modelArr
    }

    GridView {
        id: gridView
        anchors.fill: parent
        cellHeight: parent.width * 0.32
        cellWidth: parent.width * 0.25

        property var desaturation: settings.useColoredIcons ? 0.0 : 1.0

        Component.onCompleted: {
            AN.SystemDispatcher.dispatch("volla.launcher.getShortcuts", {})
        }

        model: gridModel

        currentIndex: -1

        header: Column {
            id: header
            width: parent.width
            Label {
                id: headerLabel
                topPadding: mainView.innerSpacing * 2
                x: mainView.innerSpacing
                text: qsTr("Apps")
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
            }
            TextField {
                id: textField
                padding: mainView.innerSpacing
                x: mainView.innerSpacing
                width: parent.width - mainView.innerSpacing * 2
                placeholderText: qsTr("Filter apps")
                color: mainView.fontColor
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.largeFontSize
                leftPadding: 0.0
                rightPadding: 0.0

                background: Rectangle {
                    color: "transparent"
                    border.color: "transparent"
                }
                Binding {
                    target: appLauncher
                    property: "textInput"
                    value: textField.displayText.toLowerCase()
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
                border.color: "transparent"
                color: "transparent"
                height: 1.1
            }
            //bottomPadding: mainView.innerSpacing / 2
        }

        delegate: Rectangle {
            id: gridCell
            width: parent.width * 0.25
            height: parent.width * 0.32
            color: "transparent"

            property var gradientColor: Universal.background
            property var overlayColor: Universal.foreground

            Rectangle {
                id: gridCircle
                anchors.top: gridButton.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.width * 0.6
                width: parent.width * 0.6
                color: Universal.foreground
                opacity: Universal.theme === Universal.Light ? 0.1 : 0.2
                radius: width * 0.5
            }

            Button {
                id: gridButton
                anchors.top: parent.top
                anchors.topMargin: parent.width * 0.08 // Adjustment
                topPadding: mainView.innerSpacing / 2
                width: parent.width
                text: model.label
                contentItem: Column {
                    spacing: gridCell.width * 0.25
                    Image {
                        id: buttonIcon
                        anchors.left: parent.left
                        anchors.leftMargin: gridCell.width * 0.25
                        source: model.package in appLauncher.iconMap && model.shortcutId === undefined
                                ? Qt.resolvedUrl(appLauncher.iconMap[model.package]) : "data:image/png;base64," + model.icon
                        width: gridButton.width * 0.35
                        height: gridButton.width * 0.35

                        ColorOverlay {
                            anchors.fill: buttonIcon
                            source: buttonIcon
                            color: gridCell.overlayColor
                            visible: (model.package in appLauncher.iconMap) && model.shortcutId === undefined
                        }
                    }
                    Label {
                        id: buttonLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: gridButton.width - mainView.innerSpacing
                        horizontalAlignment: contentWidth > gridButton.width - mainView.innerSpacing ? Text.AlignLeft : Text.AlignHCenter
                        text: gridButton.text
                        font.pointSize: appLauncher.labelPointSize
                        clip: mainView.backgroundOpacity === 1.0 ? true : false
                        elide: mainView.backgroundOpacity === 1.0 ? Text.ElideNone :  Text.ElideRight
                    }
                }
                flat:true
                background: Rectangle {
                    color: "transparent"
                    border.color: "transparent"
                }
                onClicked: {
                    if (gridView.currentIndex > -1) {
                        contextMenu.dismiss()
                        gridView.currentIndex = -1
                    } else if (model.package.length > 0) {
                        console.log("App " + model.label + " selected")
                        // As a workaround for a missing feature in the phone app
                        if (model.package === mainView.phoneApp) {
                            if (appLauncher.newCalls) {
                                AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp, "action": "log"})
                                AN.SystemDispatcher.dispatch("volla.launcher.updateCallsAsRead", { })
                            } else {
                                AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp})
                            }
                        } else if (model.shortcutId !== undefined) {
                            AN.SystemDispatcher.dispatch("volla.launcher.launchShortcut",
                                                         {"shortcutId": model.shortcutId, "package": model.package})
                        } else {
                            AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": model.package})
                        }
                    }
                }
                onPressAndHold: {
                    gridView.currentIndex = index
                    contextMenu.app = model
                    contextMenu.isPinnedShortcut = model.shortcutId !== undefined
                    contextMenu.popup(gridCell)
                }
            }

            Desaturate {
                anchors.fill: gridButton
                source: gridButton
                desaturation: gridView.desaturation
            }

            LinearGradient {
                id: labelTruncator
                height: parent.height
                width: parent.width //+ parent.width * 0.2
                start: Qt.point(parent.width - mainView.innerSpacing, 0)
                end: Qt.point(parent.width,0)
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#00000000"
                    }
                    GradientStop {
                        position: 1.0
                        color: gridCell.gradientColor
                    }
                }
                visible: mainView.backgroundOpacity === 1.0
            }

            Rectangle {
                id: notificationBadge
                visible: mainView.messageApp.includes(model.package) ? appLauncher.unreadMessages
                                                                     : model.package === mainView.phoneApp ? appLauncher.newCalls                                                               : false
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: (parent.width - parent.width * 0.6) * 0.5
                width: parent.width * 0.15
                height: parent.width * 0.15
                radius: height * 0.5
                color:  Universal.accent
            }
        }
    }

    Menu {
        id: contextMenu

        property double menuWidth: 250.0
        property var app
        property bool isPinnedShortcut: false

        background: Rectangle {
            id: menuBackground
            height: contextMenu.isPinnedShortcut ? 150 : 110
            implicitWidth: contextMenu.menuWidth
            color: Universal.accent
            radius: mainView.innerSpacing
        }

        MenuItem {
            id: addShortCutItem
            text: qsTr("Add to shortcuts")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: contextMenu.menuWidth
                text: addShortCutItem.text
                font: addShortCutItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            leftPadding: mainView.innerSpacing
            rightPadding: mainView.innerSpacing
            topPadding: mainView.innerSpacing
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | App " + contextMenu.app["label"] + " selected for shortcuts");
                gridView.currentIndex = -1
                mainView.updateAction(contextMenu.app["itemId"],
                                      true,
                                      mainView.settingsAction.CREATE,
                                      {"id": contextMenu.app["itemId"],
                                       "name": qsTr("Open") + " " + contextMenu.app["label"],
                                       "activated": true} )
            }
        }
        MenuItem {
            id: openAppItem
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: contextMenu.menuWidth
                text: contextMenu.isPinnedShortcut ? qsTr("Open Shortcut") : qsTr("Open App")
                horizontalAlignment: Text.AlignHCenter
            }
            leftPadding: mainView.innerSpacing
            rightPadding: mainView.innerSpacing
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | App " + contextMenu.
                            app["label"] + " selected to open");
                gridView.currentIndex = -1
                if (contextMenu.isPinnedShortcut) {
                    AN.SystemDispatcher.dispatch("volla.launcher.launchShortcut",
                                                 {"shortcutId": contextMenu.app["itemId"], "package": contextMenu.app["package"]})
                } else if (contextMenu.app.package === mainView.phoneApp) {
                    if (appLauncher.newCalls) {
                        AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp, "action": "log"})
                        AN.SystemDispatcher.dispatch("volla.launcher.updateCallsAsRead", { })
                    } else {
                        AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp})
                    }
                } else {
                    AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": contextMenu.app["package"]})
                }
            }
        }
        MenuItem {
            id: removeShortcutItem
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: contextMenu.menuWidth
                text: qsTr("Remove Shortcut")
                horizontalAlignment: Text.AlignHCenter
            }
            leftPadding: mainView.innerSpacing
            rightPadding: mainView.innerSpacing
            bottomPadding: mainView.innerSpacing
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            visible: contextMenu.isPinnedShortcut
            onClicked: {
                console.log("AppGrid | App " + contextMenu.app.shortcutId + " selected to remove a shortcut");
                gridView.currentIndex = -1
                var shortcutId = contextMenu.app["itemId"]
                gridModel.removePinnedShortcut(shortcutId)
                AN.SystemDispatcher.dispatch("volla.launcher.removeShortcut", {"shortcutId": shortcutId})
                disabledPinnedShortcuts.disableShortcut(shortcutId)
            }
        }
    }

    ListModel {
        id: gridModel

        property var apps: new Array
        property var pinnedShortcuts: new Array
        property var modelArr: new Array

        function prepareModel() {
            modelArr = pinnedShortcuts.concat(apps)
            modelArr.forEach(function(app, i) {
                modelArr[i].label = app.package in appLauncher.labelMap && app.shortcutId === undefined
                        ? qsTr(appLauncher.labelMap[app.package]) : app.label
                modelArr[i].itemId = app.shortcutId !== undefined ? app.shortcutId : app.package
            })
        }

        function update(text) {
            console.log("AppGrid | Update model with text input: " + text)

            var filteredGridDict = new Object
            var filteredGridItem
            var gridItem
            var found
            var i

            console.log("Model has " + modelArr.length + " elements")

            // filter model
            for (i = 0; i < modelArr.length; i++) {
                filteredGridItem = modelArr[i]
                var modelItemName = modelArr[i].label
                var modelItemId = modelArr[i].itemId
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    // console.log("Add " + modelItemName + " to filtered items")
                    filteredGridDict[modelItemId] = filteredGridItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemId = get(i).itemId
                existingGridDict[modelItemId] = true
            }

            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemId = get(i).itemId
                found = filteredGridDict.hasOwnProperty(modelItemId)
                if (!found) {
                    console.log("GridView | Remove " + modelItemId)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            var keys = Object.keys(filteredGridDict)
            keys.forEach(function(key) {
                found = existingGridDict.hasOwnProperty(key)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredGridItem = filteredGridDict[key]
                    // console.log("Will append " + filteredGridItem.label)
                    append(filteredGridItem)
                }
            })

            sortModel()
        }

        function sortModel() {
            var n;
            var i;
            for (n = 0; n < count; n++) {
                for (i=n+1; i < count; i++) {
                    if (get(n).label.toLowerCase() > get(i).label.toLowerCase()) {
                        move(i, n, 1);
                        n = 0;
                    }
                }
            }
        }

        function removePinnedShortcut(shorcutId) {
            pinnedShortcuts = pinnedShortcuts.filter(function(item) {
                return item.itemId !== shorcutId
            })
            prepareModel()
            update(textInput)
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.appCountResponse") {
                if (message["appCount"] !== appLauncher.appCount) {
                    console.log("AppGrid | Number of apps: " + message["appCount"], ", " + appLauncher.appCount)
                    appLauncher.appCount = message["appCount"]
                    mainView.updateSpinner(true)
                    AN.SystemDispatcher.dispatch("volla.launcher.appAction", new Object)
                }
            } else if (type === "volla.launcher.appResponse") {
                console.log("AppGrid | " + message["appsCount"] + " app infos received")
                settings.sync()
                gridModel.apps = message["apps"]
                gridModel.prepareModel()
                gridModel.update(textInput)
                mainView.updateSpinner(false)
            } else if (type === "volla.launcher.callLogResponse") {
                console.log("AppGrid | Missed calls: " + message["callsCount"])
                appLauncher.newCalls = message["callsCount"] > 0
            } else if (type === "volla.launcher.threadsCountResponse") {
                console.log("AppGrid | Unread messages: " + message["threadsCount"])
                appLauncher.unreadMessages = message["threadsCount"] > 0
            } else if (type === "volla.launcher.receivedShortcut") {
                //console.log("AppGrid | New pinned shortcut: " + message["shortcutId"])

                var isExistingShortcut = gridModel.modelArr.some( function(app) {
                    return app.shorcutId !== undefined && app.shortcutId === message.shortcutId && app.package === message.package
                })
                if (!isExistingShortcut) {
                    //mainView.showToast(qsTr("New pinned shortcut: " + message.shortcutId))
                    var shortcut = {"shortcutId": message["shortcutId"],
                                    "package": message["package"],
                                    "label": message["label"],
                                    "icon": message["icon"]}

                    //mainView.showToast(shortcut["shortcutId"]);

                    if (shortcut["shortcutId"] === undefined) mainView.showToast("ERROR: Undefined Shortcut Id")
                    if (shortcut["icon"] === undefined) mainView.showToast("ERROR: Undefined Shortcut Icin")

                    gridModel.pinnedShortcuts.push(shortcut)
                    gridModel.clear()
                    gridModel.modelArr = new Array
                    gridModel.prepareModel()
                    gridModel.update(textInput)

                    var disabledShortcutIds = disabledPinnedShortcuts.getShortcutIds()

                    var i = disabledShortcutIds.indexOf(shortcut["shortcutId"])
                    if (i >= 0) {
                        disabledShortcutIds.splice(i, 1)
                        disabledPinnedShortcuts.saveShortcutIds(disabledShortcutIds)
                    }
                } else {
                    mainView.showToast(qsTr("Pinned shortcut already exists"))
                }
            } else if (type === "volla.launcher.gotShortcuts") {
                console.log("AppGrid | Pinned shortcuts received: " + message["pinnedShortcuts"].length)
                if (message["pinnedShortcuts"].length > 0) {
                    disabledShortcutIds = disabledPinnedShortcuts.getShortcutIds()
                    console.debug("AppGrid | Disabled shortcuts " + disabledShortcutIds.length)
                    for (i = 0; i < message["pinnedShortcuts"].length; i++) {
                        shortcut = message["pinnedShortcuts"][i]
                        if (disabledShortcutIds.indexOf(shortcut["shortcutId"]) < 0) {
                            gridModel.pinnedShortcuts.push(shortcut)
                        }
                    }
                    gridModel.prepareModel()
                    gridModel.update(textInput)
                }
            }
        }
    }

    Settings {
        id: settings
        property bool useColoredIcons: false

        onUseColoredIconsChanged: {
            console.log("Colered icons settings changed")
            gridView.desaturation = useColoredIcons ? 0.0 : 1.0
        }
    }

    FileIO {
        id: disabledPinnedShortcuts
        source: "dusabledShorcuts.json"
        onError: {
            console.log("AppGrid | Disabled contacts store error: " + msg)
        }
        function getShortcutIds() {
            var shortcutIds = readPrivate()
            if (shortcutIds !== undefined && shortcutIds.length > 0) {
                return JSON.parse(shortcutIds)
            } else {
                return new Array
            }
        }
        function saveShortcutIds(shortcutIds) {
            writePrivate(JSON.stringify(shortcutIds))
        }
        function disableShortcut(shortcutId) {
            var shortcutIds = readPrivate()
            if (shortcutIds !== undefined && shortcutIds.length > 0) {
                shortcutIds = JSON.parse(shortcutIds)
            } else {
                shortcutIds = new Array
            }
            shortcutIds.push(shortcutId)
            saveShortcutIds(shortcutIds)
        }
    }
}
