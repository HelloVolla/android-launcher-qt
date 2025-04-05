import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.XmlListModel 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN
import FileIO 1.0

LauncherPage {
    id: appLauncher
    anchors.fill: parent    

    property string textInput
    property real labelPointSize: 16

    property var appGroups: [] // QML elements with app grids
    property var customGroups: []
    property var toKeepMenuItems: []
    property bool enableCustomGroup: false
    property var pinnedShortcuts: []

    property int appCount: 0
    property int selectedGroup: 0
    property int maxAppCount: mainView.isTablet ? 15 : 12

    property double lastAppsCheck: 0.0

    Settings {
        id: customSettings
        property string customGroupsJSON: "[]"
    }

    function saveCustomGroups() {
        customSettings.customGroupsJSON = JSON.stringify(customGroups);
    }

    onTextInputChanged: {
        console.log("AppGrid | Text input changed: " + appLauncher.textInput)
        for (var i = 0; i < appLauncher.appGroups.length; i++) {
            var appGroup = appLauncher.appGroups[i]
            appGroup.textInput = appLauncher.textInput
        }
    }

    function updateAppLauncher(key, value) {
        console.log("AppGrid | Will update app launcher: " + key + ", " + value)
        if (key === "backgroundOpacity") {
            for (var i = 0; i < appLauncher.appGroups.length; i++) {
                var appGroup = appLauncher.appGroups[i]
                if (value !== undefined) {
                    appGroup.backgroundOpacity = value
                }
            }
        } else if (key === "useCategories") {
            settings.useCategories = value

            if (settings.useGroupedApps) {
                appLauncher.selectedGroup = 0
                var apps = getAllApps()
                appLauncher.destroyAppGroups()
                appLauncher.createAppGroups(getGroupedApps(apps))
            }
        } else if (key === "useGroupedApps") {
            settings.useGroupedApps = value
            appLauncher.selectedGroup = 0
            apps = getAllApps()
            appLauncher.destroyAppGroups()
            appLauncher.createAppGroups(getGroupedApps(apps))
        } else if (key === "coloredIcons") {
            settings.useColoredIcons = value
            for (i = 0; i < appLauncher.appGroups.length; i++) {
                appGroup = appLauncher.appGroups[i]
                appGroup.desaturation = value ? 0.0 : 1.0
            }
        }
    }

    function updateNotifications() {
        AN.SystemDispatcher.dispatch("volla.launcher.callCountAction", {"is_read": 0})
        AN.SystemDispatcher.dispatch("volla.launcher.threadsCountAction", {"read": 0})
        AN.SystemDispatcher.dispatch("volla.launcher.otherAppNotificationAction", {"read": 0})
    }

    function getAllApps() {
        var allApps = new Array
         for (var i = 0; i < appLauncher.appGroups.length; i++) {
             var appGroup = appLauncher.appGroups[i]
             allApps = allApps.concat(appGroup.apps)
        }
        return allApps
    }

    function getGroupedApps(apps) {
        enableCustomGroup = false;
        var groupedApps = new Array
        if (settings.useCategories && !settings.useGroupedApps) {
            console.debug("AppGrid | settings.useGroupedApps nly use categoy is true")
            apps.sort(function(a, b) {
                if (a.category > b.category) return 1
                else if (a.category < b.category) return -1
                else return 0
            })
            var groupLabel
            var someApps
            for (var i = 0; i < apps.length; i++) {
                var app = apps[i]

                var category = app.category !== "" ? app.category : qsTr("Other apps")
                if (category !== groupLabel) {
                    if (groupLabel !== undefined) groupedApps.push({"groupLabel": groupLabel, "apps": someApps})
                    groupLabel = category
                    someApps = new Array
                }
                someApps.push(app)
            }
            groupedApps.push({"groupLabel": groupLabel, "apps": someApps})
        }
        if (settings.useGroupedApps) {
            apps.sort(function(a, b) { return b["statistic"] - a["statistic"] })

            if (apps.length > appLauncher.maxAppCount) {
                groupedApps.push( { "groupLabel": qsTr("Most used"), "apps": apps.slice(0, appLauncher.maxAppCount) } )

                if (settings.useCategories) {
                    var remainingApps = apps.slice(appLauncher.maxAppCount)
                    remainingApps.sort(function(a, b) {
                        if (a.category > b.category) return 1
                        else if (a.category < b.category) return -1
                        else return 0
                    })
                    var groupLabel
                    var someApps
                    for (var i = 0; i < remainingApps.length; i++) {
                        var app = remainingApps[i]
                        var category = app.category !== "" ? app.category : qsTr("Other apps")
                        if (category !== groupLabel) {
                            if (groupLabel !== undefined) groupedApps.push({"groupLabel": groupLabel, "apps": someApps})
                            groupLabel = category
                            someApps = new Array
                        }
                        someApps.push(app)
                    }
                    groupedApps.push({"groupLabel": groupLabel, "apps": someApps})
                } else {
                    groupedApps.push( { "groupLabel": qsTr("apps"), "apps": apps.slice(appLauncher.maxAppCount) } )
                }
            } else {
                groupedApps.push( { "groupLabel": qsTr("Most used"), "apps": apps.slice(0,) } )
            }
        } //else {
            //groupedApps.push( { "groupLabel": qsTr("Most used"), "apps": apps } )
       // }

        if (!settings.useCategories && !settings.useGroupedApps) {
            enableCustomGroup = true
            var remainingApps = apps.slice(0)
            remainingApps.sort(function(a, b) {
                if (a.customCategory > b.customCategory) return 1
                else if (a.customCategory < b.customCategory) return -1
                else return 0
            })
            var groupLabel
            var someApps
            for (var i = 0; i < remainingApps.length; i++) {
                var app = remainingApps[i]
                var category = app.customCategory !== "" ? app.customCategory : qsTr("Other apps")
                if (category !== groupLabel) {
                    if (groupLabel !== undefined) groupedApps.push({"groupLabel": groupLabel, "apps": someApps})
                    groupLabel = category
                    someApps = new Array
                }
                someApps.push(app)
            }
            groupedApps.push({"groupLabel": groupLabel, "apps": someApps})

            shortcutMenu.visible = true;
        } else {
            shortcutMenu.visible =  false;
        }

        return groupedApps
    }

    function createAppGroups(groupedApps) {
        console.log("AppGrid | Will create app grids for " + groupedApps.length + " groups.")
        groupedApps.forEach(function(appGroupInfos, index) {
            console.log("AppGrid | Will create group " + index)
            var component = Qt.createComponent("/AppGroup.qml", appLauncherColumn)
            var properties = { "groupLabel": appGroupInfos["groupLabel"],
                               "groupIndex": index,
                               "selectedGroupIndex": appLauncher.selectedGroup,
                               "textInput": appLauncher.textInput,
                               "iconMap": mainView.iconMap,
                               "labelMap": mainView.labelMap,
                               "phoneApp": mainView.phoneApp,
                               "messageApp": mainView.messageApp,
                               "labelPointSize": appLauncher.labelPointSize,
                               "headerPointSize": mainView.mediumFontSize,
                               "innerSpacing": mainView.innerSpacing,
                               "componentSpacing" : mainView.componentSpacing,
                               "backgroundOpacity": mainView.backgroundOpacity,
                               "accentColor": mainView.accentColor,
                               "desaturation": settings.useColoredIcons ? 0.0 : 1.0,
                               "pinnedShortcuts": index === 0 ? appLauncher.pinnedShortcuts : new Array,
                               "apps": appGroupInfos["apps"]}
            if (component.status !== Component.Ready) {
                if (component.status === Component.Error)
                    console.debug("AppGrid | Error: "+ component.errorString() );
            }
            var object = component.createObject(appLauncherColumn, properties)
            appLauncher.appGroups.push(object)
        })
    }

    function destroyAppGroups() {
        for (var i = 0; i < appLauncher.appGroups.length; i++) {
            var appGroup = appLauncher.appGroups[i]
            appGroup.destroy()
        }
        appLauncher.appGroups = new Array
    }

    Flickable {
        id: appLauncherFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: appLauncherColumn.height

        Column {
            id: appLauncherColumn
            width: parent.width// - 2 * mainView.outerSpacing

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
                topPadding: mainView.componentSpacing
                bottomPadding: mainView.componentSpacing
                leftPadding: 0.0
                rightPadding: 0.0
                x: mainView.innerSpacing
                width: parent.width - mainView.innerSpacing * 2
                placeholderText: qsTr("Filter apps")
                color: mainView.fontColor
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.largeFontSize

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
                if (customSettings.customGroupsJSON) {
                       customGroups = JSON.parse(customSettings.customGroupsJSON);
                   }
            }

            function showGroup(groupIndex) {
                console.log("AppGrid | Will show group " + groupIndex)
                appLauncher.selectedGroup = groupIndex
                for (var i = 0; i < appGroups.length; i++) {
                    var appGroup = appGroups[i]
                    appGroup.showApps(i === groupIndex)
                    appGroup.selectedGroupIndex = groupIndex
                }
            }

            function openContextMenu(app, gridCell, gridView) {
                contextMenu.app = app
                contextMenu.gridView = gridView
                contextMenu.isPinnedShortcut = app.shortcutId !== undefined && app.shortcutId.length > 0
                if(enableCustomGroup){
                    for (var i = 0; i < customGroups.length; i++) {
                         contextMenu.addMenuItem(qsTr(customGroups[i]), contextMenu.app , contextMenu.myHandler);
                        contextMenu.implicitHeight += contextMenu.menuItemHeight + mainView.innerSpacing;
                    }
                }
                contextMenu.popup(gridCell)
            }

            function closeContextMenu() {
                contextMenu.dismiss()
            }
        }
    }

    Menu {
        id: contextMenu
        implicitHeight: addShortCutItem.height + openAppItem.height + removeAppItem.height + removePinnedShortcutItem.height + mainView.innerSpacing
        topPadding: mainView.innerSpacing / 2

        property double menuWidth: 250.0
        property var app
        property var gridView
        property bool isPinnedShortcut: false
        property bool canBeDeleted: false
        property int menuItemHeight: 40

        background: Rectangle {
            id: menuBackground
            implicitWidth: contextMenu.menuWidth
            color: mainView.accentColor
            radius: mainView.innerSpacing
        }

        MenuItem {
            id: addShortCutItem
            anchors.margins: mainView.innerSpacing
            text: qsTr("Add to shortcuts")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: contextMenu.menuWidth
                text: addShortCutItem.text
                font: addShortCutItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | App " + contextMenu.app["label"] + " selected for shortcuts");
                contextMenu.gridView.currentIndex = -1
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
            anchors.margins: mainView.innerSpacing
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: contextMenu.menuWidth
                text: contextMenu.isPinnedShortcut ? qsTr("Open Shortcut") : qsTr("Open App")
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | App " + contextMenu.
                            app["label"] + " selected to open");
                contextMenu.gridView.currentIndex = -1
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
            id: removeAppItem
            anchors.margins: mainView.innerSpacing
            height: removeAppItem.visible ? contextMenu.menuItemHeight : 0
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: contextMenu.menuWidth
                text: qsTr("Remove App")
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            visible: contextMenu.canBeDeleted
            onClicked: {
                    AN.SystemDispatcher.dispatch("volla.launcher.deleteAppAction", {"appId": contextMenu.app["package"]})
            }
        }
        MenuItem {
            id: removePinnedShortcutItem
            anchors.margins: mainView.innerSpacing
            height: removePinnedShortcutItem.visible ? contextMenu.menuItemHeight : 0
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: contextMenu.menuWidth
                text: qsTr("Remove Bookmark")
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            visible: contextMenu.isPinnedShortcut
            onClicked: {
                console.log("AppGrid | App " + contextMenu.app.shortcutId + " selected to remove a shortcut");
                contextMenu.gridView.currentIndex = -1
                var shortcutId = contextMenu.app["itemId"]
                for (var i = 0; i < appLauncher.appGroups.length; i++) {
                    var appGroup = appLauncher.appGroups[i]
                    appGroup.removePinnedShortcut(shortcutId)
                }
                AN.SystemDispatcher.dispatch("volla.launcher.removeShortcut", {"shortcutId": shortcutId})
                disabledPinnedShortcuts.disableShortcut(shortcutId)
            }
        }

        onAboutToShow: {
            AN.SystemDispatcher.dispatch("volla.launcher.canDeleteAppAction", {"appId": contextMenu.app["package"]})
        }

        Connections {
            target: AN.SystemDispatcher
            onDispatched: {
                if (type === "volla.launcher.canDeleteAppResponce") {
                    contextMenu.canBeDeleted = message["canDeleteApp"]
                }
            }
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.appCountResponse") {
                 if (message["appCount"] !== settings.appCount) {
                    console.log("AppGrid | Number of apps: " + message["appCount"] + ", " + settings.appCount)
                    settings.appCount = message["appCount"]
                    mainView.updateSpinner(true)
                    AN.SystemDispatcher.dispatch("volla.launcher.appAction", new Object)
                } else if (new Date().valueOf() - settings.lastAppCountCheck > 3600000) {
                    console.debug("AppGrid | Will update statistics")
                    AN.SystemDispatcher.dispatch("volla.launcher.appAction", new Object)
                } else if (settings.appCount !== appLauncher.getAllApps().length) {
                    var appsString = appsCache.readPrivate()
                    if (appsString.length > 0) {
                        console.debug("AppLauncher | Will read app cache")
                        var appsArray = JSON.parse(appsString)
                        var groupedApps = appLauncher.getGroupedApps(appsArray)
                        appLauncher.destroyAppGroups()
                        appLauncher.createAppGroups(groupedApps)
                        // Reflect different OS versions and devices
                        mainView.checkDefaultApps(appsArray)
                        // Check default phone app
                        AN.SystemDispatcher.dispatch("volla.launcher.checkPhoneAppAction", new Object)
                    } else {
                        console.log("AppLauncher | Need to retrieve apps from system")
                        mainView.updateSpinner(true)
                        AN.SystemDispatcher.dispatch("volla.launcher.appAction", new Object)
                    }
                } else {
                    console.debug("AppLauncher | Will check default phone app")
                    AN.SystemDispatcher.dispatch("volla.launcher.checkPhoneAppAction", new Object)
                }
            } else if (type === "volla.launcher.appResponse") {
                console.log("AppGrid | " + message["appsCount"] + " app infos received")
                if (settings.sync) {
                    settings.sync()
                }
                settings.lastAppCountCheck = new Date().valueOf()
                console.log("App Launcher | Did store apps: " + appsCache.writePrivate(JSON.stringify(message["apps"])))
                groupedApps = appLauncher.getGroupedApps(message["apps"])
                if (appLauncher.appGroups.length !== groupedApps.lemgth) {
                    for (var i = 0; i < appLauncher.appGroups.length; i++) {
                        var appGroup = appLauncher.appGroups[i]
                        appGroup.destroy()
                    }
                    appLauncher.appGroups = new Array
                    appLauncher.createAppGroups(groupedApps)
                } else {
                    for (i = 0; i < appLauncher.appGroups.length; i++) {
                        appLauncher.appGroup = appLauncher.appGroups[i]
                        appLauncher.appGroup.apps = groupedApps[i]["apps"]
                    }
                }
                mainView.updateSpinner(false)
                mainView.checkDefaultApps(message["apps"])
            } else if (type === "volla.launcher.receivedShortcut") {
                console.log("AppGrid | New pinned shortcut: " + message["shortcutId"])

                var shortcut = {"shortcutId": message["shortcutId"],
                                "package": message["package"],
                                "label": message["label"],
                                "icon": message["icon"] }

                if (shortcut["shortcutId"] === undefined) {
                    mainView.showToast("ERROR: Undefined Shortcut Id")
                    return
                }
                if (shortcut["icon"] === undefined) {
                    mainView.showToast("ERROR: Undefined Shortcut Icin")
                    return
                }

                var disabledShortcutIds = disabledPinnedShortcuts.getShortcutIds()

                i = disabledShortcutIds.indexOf(shortcut["shortcutId"])
                if (i >= 0) {
                    disabledShortcutIds.splice(i, 1)
                    disabledPinnedShortcuts.saveShortcutIds(disabledShortcutIds)
                }

                var isExistingShortcut = appLauncher.pinnedShortcuts.some( function(app) {
                    return app.shorcutId !== undefined && app.shortcutId === message.shortcutId && app.package === message.package
                })
                if (!isExistingShortcut) {
                    mainView.showToast(qsTr("New pinned shortcut") + ": " + message["label"])
                    appLauncher.pinnedShortcuts.push(shortcut)
                    appGroup = appGroups[0]
                    if (appGroup !== undefined) {
                        appGroup.pinnedShortcuts = appLauncher.pinnedShortcuts
                    }
                } else {
                    mainView.showToast(qsTr("Pinned shortcut already exists") + ": " + message["label"])
                }
            } else if (type === "volla.launcher.gotShortcuts") {
                console.log("AppGrid | Pinned shortcuts received: " + message["pinnedShortcuts"].length)
                if (message["pinnedShortcuts"].length > 0) {
                    disabledShortcutIds = disabledPinnedShortcuts.getShortcutIds()
                    console.debug("AppGrid | Disabled shortcuts " + disabledShortcutIds.length)
                    var pinnedShortcuts = new Array
                    for (i = 0; i < message["pinnedShortcuts"].length; i++) {
                        shortcut = message["pinnedShortcuts"][i]
                        if (disabledShortcutIds.indexOf(shortcut["shortcutId"]) < 0) {
                            pinnedShortcuts.push(shortcut)
                        }
                    }
                    appLauncher.pinnedShortcuts = pinnedShortcuts
                    appGroup = appGroups[0]
                    if (appGroup !== undefined) {
                        appGroup.pinnedShortcuts = appLauncher.pinnedShortcuts
                    }
                }
            } else if (type === "volla.launcher.checkPhoneAppResponse") {
                console.log("AppGrid | Default phone app received: " + message["phoneApp"])
                getAllApps()
                var index = getAllApps().findIndex( element => {
                    if (element.package === "com.android.dialer") {
                        return true;
                    }
                })
                if (index > -1 && "com.android.dialer" === message["phoneApp"]) {
                    console.debug("AppGrid | Will update apps")
                    AN.SystemDispatcher.dispatch("volla.launcher.appAction", new Object)
                }
            }
        }
    }

    Settings {
        id: settings
        property bool useColoredIcons: false
        property bool useGroupedApps: true
        property bool useCategories: false
        property int appCount: 0
        property double lastAppCountCheck: 0.0
    }

    FileIO {
        id: disabledPinnedShortcuts
        source: "dusabledShorcuts.json"
        onError: {
            console.log("AppGrid | Disabled shortcuts store error: " + msg)
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

    FileIO {
        id: appsCache
        source: "apps.json"
        onError: {
            console.log("AppLaunchr | Apps cache error: " + msg)
        }
    }
}
