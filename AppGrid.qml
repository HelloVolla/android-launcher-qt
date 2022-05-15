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
        "de.baumann.weather": "Wetter"
    }

    property var appGroups: [] // QML elements with app grids

    property int appCount: 0
    property int selectedGroup: 0
    property int maxAppCount: 12

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    onTextInputChanged: {
        console.log("AppGrid | Text input changed: " + appLauncher.textInput)
        for (var i = 0; i < appLauncher.appGroups.length; i++) {
            var appGroup = appLauncher.appGroups[i]
            appGroup.textInput = appLauncher.textInput
        }
    }

    function updateAppLauncher(useColoredAppIcons) {
        settings.sync()
        for (var i = 0; i < appLauncher.appGroups.length; i++) {
            var appGroup = appLauncher.appGroups[i]
            appGroup.desaturation = useColoredAppIcons ? 0.0 : 1.0
        }
    }

    function updateNotifications() {
        AN.SystemDispatcher.dispatch("volla.launcher.callLogAction", {"is_read": 0})
        AN.SystemDispatcher.dispatch("volla.launcher.threadsCountAction", {"read": 0})
    }

    function getAllApps() {
        var allApps = new Array
        for (var appGroup in appLauncher.appGroups) {
            allApps = allApps.concat(appGroup.apps)
        }
        return allApps
    }

    function getGroupedApps(apps) {
        var groupedApps = new Array
        apps.sort(function(a, b) {
            if (a.label > b.label) return 1
            else if (a.label < b.label) return -1
            else return 0
        })

        // todo: Implement category grouping

        if (apps.length > appLauncher.maxAppCount) {
            groupedApps.push( { "groupLabel": qsTr("Most used"), "apps": apps.slice(0, appLauncher.maxAppCount) } )
            groupedApps.push( { "groupLabel": qsTr("apps"), "apps": apps.slice(appLauncher.maxAppCount + 1) } )
        } else {
            groupedApps.push( { "groupLabel": qsTr("Most used"), "apps": apps.slice(0,) } )
        }
        return groupedApps
    }

    function createAppGroups(groupedApps) {
        console.log("AppGrid | Will greate app groups for " + groupedApps.length + " groups.")
        if (appLauncher.labelMap !== undefined )
            console.log("AppGrid | Label map has " + Object.keys(appLauncher.labelMap).length + " elemens.")
        else
            console.log("AppGrid | Label map is undefined")
        groupedApps.forEach(function(appGroupInfos, index) {
            console.log("AppGrid | Will create group " + index)
            var component = Qt.createComponent("/AppGroup.qml", appLauncherColumn)
            var properties = { "groupLabel": appGroupInfos["groupLabel"],
                               "groupIndex": index,
                               "selectedGroupIndex": appLauncher.selectedGroup,
                               "textInput": appLauncher.textInput,
                               "iconMap": appLauncher.iconMap,
                               "labelMap": appLauncher.labelMap,
                               "labelPointSize": appLauncher.labelPointSize,
                               "headerPointSize": mainView.mediumFontSize,
                               "innerSpacing": mainView.innerSpacing,
                               "backgroundOpacity": mainView.backgroundOpacity,
                               "apps": appGroupInfos["apps"]}
            if (component.status !== Component.Ready) {
                if (component.status === Component.Error)
                    console.debug("AppGrid | Error: "+ component.errorString() );
            }
            var object = component.createObject(appLauncherColumn, properties)
            appLauncher.appGroups.push(object)
        })
    }

    Flickable {
        id: appLauncherFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: appLauncherColumn.height

        Column {
            id: appLauncherColumn
            width: parent.width

            Label {
                id: headerTitle
                topPadding: mainView.innerSpacing * 2
                x: mainView.innerSpacing
                text: qsTr("Apps")
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
            }

            TextField {
                id: headerTextField
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
                    value: headerTextField.displayText.toLowerCase()
                }

                Button {
                    id: headerDeleteButton
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: mainView.largeFontSize * 2
                    flat: true
                    topPadding: 0.0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    visible: headerTextField.displayText !== ""

                    onClicked: {
                        headerTextField.text = ""
                        headerTextField.focus = false
                    }
                }
            }

            Component.onCompleted: {
                console.log("AppGrid | Column completed")
                AN.SystemDispatcher.dispatch("volla.launcher.getShortcuts", {})
                //AN.SystemDispatcher.dispatch("volla.launcher.appCountAction", {})
            }

            function showGroup(groupIndex) {
                console.log("AppGrid | Will show group " + groupIndex)
                appLauncher.selectedGroup = groupIndex
                for (var i = 0; i < appGroups.length; i++) {
                    var appGroup = appGroups[i]
                    appGroup.showApps(i === groupIndex)
                }
            }

            function openContextMenu(app, gridCell) {
                contextMenu.app = app
                contextMenu.isPinnedShortcut = app.shortcutId !== undefined
                contextMenu.popup(gridCell)
            }

            function closeContextMenu() {
                contextMenu.dismiss()
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
                for (var appGroup in appLauncher.appGroups) {
                    appGroup.removePinnedShortcut(shortcutId)
                }
                AN.SystemDispatcher.dispatch("volla.launcher.removeShortcut", {"shortcutId": shortcutId})
                disabledPinnedShortcuts.disableShortcut(shortcutId)
            }
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
                var groupedApps = appLauncher.getGroupedApps(message["apps"])
                if (appLauncher.appGroups.length !== groupedApps.lemgth) {
                    for (var i = 0; i < appLauncher.appGroups.length; i++) {
                        var appGroup = appLauncher.appGroups[i]
                        appGroup.destroy()
                    }
                    appLauncher.appGroups = new Array
                    appLauncher.createAppGroups(groupedApps)
                } else {
                    for (i = 0; i < appLauncher.appGroups.length; i++) {
                        appGroup = appLauncher.appGroups[i]
                        appGroup.apps = groupedApps[i]["apps"]
                    }
                }
                mainView.updateSpinner(false)
            } else if (type === "volla.launcher.receivedShortcut") {
                console.log("AppGrid | New pinned shortcut: " + message["shortcutId"])

                var isExistingShortcut = gridModel.modelArr.some( function(app) {
                    return app.shorcutId !== undefined && app.shortcutId === message.shortcutId && app.package === message.package
                })
                if (!isExistingShortcut) {
                    var shortcut = {"shortcutId": message["shortcutId"],
                                    "package": message["package"],
                                    "label": message["label"],
                                    "icon": message["icon"] }

                    if (shortcut["shortcutId"] === undefined) mainView.showToast("ERROR: Undefined Shortcut Id")
                    if (shortcut["icon"] === undefined) mainView.showToast("ERROR: Undefined Shortcut Icin")

                    appGroup = appLauncher.appGroups[0]
                    appGroup.pinnedShortcuts.push(shortcut)

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
                    appGroup = appLauncher.appGroups[0]
                    var pinnedShortcuts = new Array
                    for (i = 0; i < message["pinnedShortcuts"].length; i++) {
                        shortcut = message["pinnedShortcuts"][i]
                        if (disabledShortcutIds.indexOf(shortcut["shortcutId"]) < 0) {
                            pinnedShortcuts.push(shortcut)
                        }
                    }
                    appGroup.pinnedShortcuts = pinnedShortcuts
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
