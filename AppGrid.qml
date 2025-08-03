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
    property var pinnedShortcuts: []

    property int appCount: 0
    property int selectedGroup: 0
    property int maxAppCount: mainView.isTablet ? 15 : 12

    property double lastAppsCheck: 0.0

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
            appLauncher.selectedGroup = 0
            var apps = getAllApps()
            appLauncher.destroyAppGroups()
            appLauncher.createAppGroups(getGroupedApps(apps))
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
        console.debug("AppGrid | getGroupedApps: " + apps.length + " apps")
        var groupedApps = new Array

        // A. Group most frequent apps
        // B. Group apps by categries
        // C. Show custom app groups, of not A or B

        if (settings.useGroupedApps) {
            apps.sort(function(a, b) { return b["statistic"] - a["statistic"] })

            if (apps.length > appLauncher.maxAppCount) {
                groupedApps.push( { "groupLabel": qsTr("Most used"), "apps": apps.slice(0, appLauncher.maxAppCount) } )

                if (settings.useCategories) {
                    var remainingApps = apps.slice(appLauncher.maxAppCount)
                    createAppGroupsByCategory(remainingApps, groupedApps, false) // todo: test updated dictionary
                } else {
                    groupedApps.push( { "groupLabel": qsTr("apps"), "apps": apps.slice(appLauncher.maxAppCount) } )
                }
            } else {
                groupedApps.push( { "groupLabel": qsTr("Most used"), "apps": apps.slice(0) } )
            }
        } else if (settings.useCategories) {
            createAppGroupsByCategory(apps, groupedApps, false)
        } else {
            var customGroups = settings.getCustomGroups()
            console.debug("AppGrid | getGroupedApps: customGroups " + Object.keys(customGroups).length)
            console.debug("AppGrid | getGroupedApps: customGroups " + JSON.stringify(customGroups))
            apps.forEach(function (app, index) {
                var filteredGroupNames = Object.keys(customGroups).filter(key => customGroups[key].includes(app.package))
                if (filteredGroupNames.length > 0) {
                    app.customCategory = filteredGroupNames[0]
                }
            })
            //apps.sort(function(a, b) { return b["customCategory"] - a["customCategory"] })
            createAppGroupsByCategory(apps, groupedApps, true)
        }

        return groupedApps
    }

    function createAppGroupsByCategory(appsToGroup, groupedApps, useCustomGroups) {
        console.debug("AppGrid | createAppGroupsByCategory: ", appsToGroup.length, groupedApps.length, useCustomGroups)

        var categoryKey = useCustomGroups ? "customCategory" : "category"
        appsToGroup.sort(function(a, b) {
            var aa = a[categoryKey] !== undefined ? a[categoryKey] : ""
            var bb = b[categoryKey] !== undefined ? b[categoryKey] : ""
            if (aa > bb) return 1
            else if (aa < bb) return -1
            else return 0
        })
        var groupLabel
        var someApps
        for (var i = 0; i < appsToGroup.length; i++) {
            var app = appsToGroup[i]
            var category = app[categoryKey] === undefined || app[categoryKey] === "" ? qsTr("Other apps") : app[categoryKey]
            if (category !== groupLabel) {
                if (groupLabel !== undefined) {
                    console.debug("AppGrid | createAppGroupsByCategory: Will push " + groupLabel + ": " + someApps.length)
                    groupedApps.push({"groupLabel": groupLabel, "apps": someApps})
                }
                groupLabel = category
                someApps = new Array
            }
            someApps.push(app)
        }
        console.debug("AppGrid | createAppGroupsByCategory: Will finally push " + groupLabel + ": " + someApps.length)
        groupedApps.push({"groupLabel": groupLabel, "apps": someApps})
    }

    function createAppGroups(groupedApps) {
        console.log("AppGrid | Will create app grids for " + groupedApps.length + " group(s).")
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

    function updateCustomGroupOfApp(appToUpdate, appGroupName) {
        console.debug("AppGrid | updateCustomGroupOfApp: " + appToUpdate + ", " + appGroupName)
        var customGroups = settings.getCustomGroups()
        var customGroup = customGroups[appGroupName]
        var apps = appLauncher.getAllApps()

        var app = apps.filter(e => e.package === appToUpdate)[0]
        if (appGroupName !== undefined) {
            app.customCategory = appGroupName
            // Add to group
            if (customGroup !== undefined) {
                customGroup.push(appToUpdate)
            } else {
                customGroup = [appToUpdate]
            }
            customGroups[appGroupName] = customGroup

        } else {
                app.delete(customCategory)
                // Remove from group
                if (customGroup !== undefined) {
                    customGroup.splice(customGroup.indexOf(appGroupName, 1))
                    customGroups[appGroupName] = customGroup
                }
            }

        updateCustomGroupedAppGrid(apps, customGroups)
    }

    function updateCustomGroup(oldGroupName, newGroupName) {
        console.debug("AppGrid | updateCustomGroup: " + oldGroupName + ", " + newGroupName)
        var customGroups = settings.getCustomGroups()
        var customGroup = customGroups[oldGroupName]
        var apps = appLauncher.getAllApps()
        customGroup.forEach(function (item, index) {
            var app = apps.filter(e => e.package === item.package)[0]
            app.customCategory = newGroupName
        })
        customGroups[newGroupName] = customGroup
        customGroups = Object.fromEntries(
            Object.entries(customGroups).filter(([key]) => key !== oldGroupName)
        )
        updateCustomGroupedAppGrid(apps, customGroups)
    }

    function removeCustomGroup(appGroupName) {
        console.debug("AppGrid | removeCustomGroup: " + appGroupName)
        var customGroups = settings.getCustomGroups()
        var customGroup = customGroups[appGroupName]
        var apps = appLauncher.getAllApps()
        customGroup.forEach(function (appPackage, index) {
            apps.forEach(function (app, index) {
                if (app.package === appPackage) delete app.customCategory
            })
        })
        delete customGroups[appGroupName]
        updateCustomGroupedAppGrid(apps, customGroups)
    }

    function updateCustomGroupedAppGrid(apps, updatedCustomGroups) {
        settings.setCustomGroups(updatedCustomGroups)

        for (var i = 0; i < appLauncher.appGroups.length; i++) {
            var appGroup = appLauncher.appGroups[i]
            appGroup.destroy()
        }

        console.debug("AppGrid | Number of apps: " + apps.length)

        var groupedApps = appLauncher.getGroupedApps(apps)
        appLauncher.appGroups = new Array
        appLauncher.createAppGroups(groupedApps)
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

            function openAppContextMenu(app, gridCell, gridView) {
                appContextMenu.app = app
                appContextMenu.gridView = gridView
                appContextMenu.isPinnedShortcut = app.shortcutId !== undefined && app.shortcutId.length > 0
                appContextMenu.canBeDeleted = false
                appContextMenu.useCustomGroups = !(settings.useGroupedApps || settings.useCategories)
                if (appContextMenu.useCustomGroups) appContextMenu.createCustomGroupMenuItems()
                appContextMenu.popup(gridCell)
            }

            function closeAppContextMenu() {
               appContextMenu.dismiss()
            }

            function openGroupContextMenu(appGroup, groupButton, gridView) {
                groupContextMenu.appGroupName = appGroup.text
                groupContextMenu.appGridView = gridView
                groupContextMenu.popup(groupButton)
            }
        }
    }

    Menu {
        id: appContextMenu
        topPadding: mainView.innerSpacing / 2
        bottomPadding: mainView.innerSpacing / 2

        property double menuWidth: 250.0
        property var app: new Object
        property var gridView
        property var customGroupMenuItems: new Array
        property bool isPinnedShortcut: false
        property bool canBeDeleted: false
        property bool useCustomGroups: false
        property int menuItemHeight: 40

        onAppChanged: {
            if (app !== undefined && app !== null) console.debug("AppGrid | App of context menu: " + appContextMenu.app.package)
            else console.debug("AppGrid | App of context menu: " + appContextMenu.app)
            implicitHeight: addShortCutItem.height  + openAppItem.height + removeAppItem.height  + removePinnedShortcutItem.height
                            + addToNewGroupItem.height + removeFromGroupItem.height + enableCustomGroupsItem.height + mainView.innerSpacing
        }

        background: Rectangle {
            implicitWidth: appContextMenu.menuWidth
            color: mainView.accentColor
            radius: mainView.innerSpacing
        }

        MenuItem {
            id: addShortCutItem
            anchors.margins: mainView.innerSpacing
            text: qsTr("Add to shortcuts")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: appContextMenu.menuWidth
                text: addShortCutItem.text
                font: addShortCutItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | App " + appContextMenu.app["label"] + " selected for shortcuts");
                appContextMenu.gridView.currentIndex = -1
                mainView.updateAction(contextMenu.app["itemId"],
                                      true,
                                      mainView.settingsAction.CREATE,
                                      {"id": appContextMenu.app["itemId"],
                                       "name": qsTr("Open") + " " + appContextMenu.app["label"],
                                       "activated": true} )
            }
        }
        MenuItem {
            id: openAppItem
            anchors.margins: mainView.innerSpacing
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width:appContextMenu.menuWidth
                text:appContextMenu.isPinnedShortcut ? qsTr("Open Shortcut") : qsTr("Open App")
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | App " + appContextMenu.
                            app["label"] + " selected to open");
                appContextMenu.gridView.currentIndex = -1
                if (contextMenu.isPinnedShortcut) {
                    AN.SystemDispatcher.dispatch("volla.launcher.launchShortcut",
                                                 {"shortcutId": appContextMenu.app["itemId"], "package": appContextMenu.app["package"]})
                } else if (contextMenu.app.package === mainView.phoneApp) {
                    if (appLauncher.newCalls) {
                        AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp, "action": "log"})
                        AN.SystemDispatcher.dispatch("volla.launcher.updateCallsAsRead", { })
                    } else {
                        AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp})
                    }
                } else {
                    AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": appContextMenu.app["package"]})
                }
            }
        }
        MenuItem {
            id: removeAppItem
            anchors.margins: mainView.innerSpacing
            height: removeAppItem.visible ? appContextMenu.menuItemHeight : 0
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: appContextMenu.menuWidth
                text: qsTr("Remove App")
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            visible: appContextMenu.canBeDeleted
            onClicked: {
                    AN.SystemDispatcher.dispatch("volla.launcher.deleteAppAction", {"appId":appcontextMenu.app["package"]})
            }
        }
        MenuItem {
            id: removePinnedShortcutItem
            anchors.margins: mainView.innerSpacing
            height: removePinnedShortcutItem.visible ? appContextMenu.menuItemHeight : 0
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: appContextMenu.menuWidth
                text: qsTr("Remove Bookmark")
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            visible: appContextMenu.isPinnedShortcut
            onClicked: {
                console.log("AppGrid | App " + appContextMenu.app.shortcutId + " selected to remove a shortcut");
                appContextMenu.gridView.currentIndex = -1
                var shortcutId = appContextMenu.app["itemId"]
                for (var i = 0; i < appLauncher.appGroups.length; i++) {
                    var appGroup = appLauncher.appGroups[i]
                    appGroup.removePinnedShortcut(shortcutId)
                }
                AN.SystemDispatcher.dispatch("volla.launcher.removeShortcut", {"shortcutId": shortcutId})
                disabledPinnedShortcuts.disableShortcut(shortcutId)
            }
        }
        MenuItem {
            id: addToNewGroupItem
            visible: appContextMenu.useCustomGroups
            anchors.margins: mainView.innerSpacing
            height: addToNewGroupItem.visible ? appContextMenu.menuItemHeight : 0
            text: qsTr("Add to new group")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: appContextMenu.menuWidth
                text: addToNewGroupItem.text
                font: addToNewGroupItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                groupDialog.app = appContextMenu.app
                groupDialog.open()
            }
        }
        MenuItem {
            id: removeFromGroupItem
            visible: appContextMenu.useCustomGroups && appContextMenu.app !== null && appContextMenu.app.customCategory !== undefined
            anchors.margins: mainView.innerSpacing
            height: removeFromGroupItem.visible ? appContextMenu.menuItemHeight : 0
            text: qsTr("Remove from group")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: appContextMenu.menuWidth
                text: removeFromGroupItem.text
                font: removeFromGroupItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                appContextMenu.updateCustomGroupOfApp(appContextMenu.app.package)
            }
        }
        MenuItem {
            id: enableCustomGroupsItem
            visible: !appContextMenu.useCustomGroups
            anchors.margins: mainView.innerSpacing
            height: enableCustomGroupsItem.visible ? appContextMenu.menuItemHeight : 0
            text: qsTr("Use custom groups")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: appContextMenu.menuWidth
                text: enableCustomGroupsItem.text
                font: enableCustomGroupsItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | Enable custom groups");
                settings.useGroupedApps = false
                settings.useCategories = false
                settings.sync()
                var apps = getAllApps()
                appLauncher.destroyAppGroups()
                appLauncher.selectedGroup = 0
                appLauncher.createAppGroups(getGroupedApps(apps))
            }
        }

        onAboutToShow: {
            AN.SystemDispatcher.dispatch("volla.launcher.canDeleteAppAction", {"appId": appContextMenu.app["package"]})
            implicitHeight: appContextMenu.count * appContextMenu.menuItemHeight
        }

        onAboutToHide: {
            for (var i = 0; i < customGroupMenuItems.length; i++) {
                var customGroupMenuItem = customGroupMenuItems[i]
                appContextMenu.removeItem(customGroupMenuItem)
                customGroupMenuItem.destroy()
            }
            customGroupMenuItems = new Array
        }

        function createCustomGroupMenuItems() {
            var customGroups = settings.getCustomGroups()
            console.log("AppGrid | createCustomGroupMenuItems: " + Object.keys(customGroups).length)
            Object.keys(customGroups).forEach(key => {
                console.log("AppGrid | createCustomGroupMenuItems: " + key)
                var component = Qt.createComponent("/AppGridMenuItem.qml", appContextMenu)
                var properties = { "height": appContextMenu.menuItemHeight, "innerSpacing" : mainView.innerSpacing,
                                   "labelPointSize" : appLauncher.labelPointSize, "labelWidth" : appContextMenu.menuWidth,
                                   "appPackageName" : app.package, "appGroup" : key, "appLauncher": appLauncher}
                var object = component.createObject(appContextMenu, properties)
                appContextMenu.addItem(object)
                console.log("AppGrid | createCustomGroupMenuItems: Menu items " + appContextMenu.count)
                customGroupMenuItems.push(object)
            });
        }
   }

    Menu {
        id: groupContextMenu
        implicitHeight: removeMenuItem.height + editMenuItem.height + mainView.innerSpacing
        topPadding: mainView.innerSpacing / 2

        background: Rectangle {
            implicitWidth: appContextMenu.menuWidth
            color: mainView.accentColor
            radius: mainView.innerSpacing
        }

        property var appGroupName
        property var appGridView

        MenuItem {
            id: removeMenuItem
            anchors.margins: mainView.innerSpacing
            text: qsTr("Remove group")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: removeMenuItem.menuWidth
                text: removeMenuItem.text
                font: removeMenuItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | Remove group " + groupContextMenu.appGroupName);
                appLauncher.removeCustomGroup(groupContextMenu.appGroupName)
            }
        }
        MenuItem {
            id: editMenuItem
            anchors.margins: mainView.innerSpacing
            text: qsTr("Edit groupname")
            font.pointSize: appLauncher.labelPointSize
            contentItem: Label {
                width: editMenuItem.menuWidth
                text: editMenuItem.text
                font: editMenuItem.font
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            onClicked: {
                console.log("AppGrid | Edit group " + groupContextMenu.appGroupName);
                groupDialog.groupName = groupContextMenu.appGroupName
                groupDialog.open()
            }
        }
    }

    Dialog {
        id: groupDialog

        anchors.centerIn: parent
        width: parent.width - mainView.innerSpacing * 4
        modal: true
        dim: false

        property var app
        property string groupName: ""

        onGroupNameChanged: {
            groupNameField.text = groupName
        }

        background: Rectangle {
            anchors.fill: parent
            color: "#292929"
            border.color: "transparent"
            radius: mainView.innerSpacing / 2
        }

        enter: Transition {
             NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
        }

        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
        }

        contentItem: Column {
            id: groupDialogColumn

            Label {
                id: dialogTitle
                text: qsTr("Group name")
                color: mainView.fontColor
                font.pointSize: mainView.mediumFontSize
                bottomPadding: mainView.innerSpacing
                background: Rectangle {
                    color: "transparent"
                    border.color: "transparent"
                }
            }

            TextField {
                id: groupNameField
                width: parent.width
                color: mainView.fontColor
                maximumLength: 80
                wrapMode: Text.NoWrap
                placeholderText: qsTr("Enter a group name")
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.mediumFontSize
                background: Rectangle {
                    color: mainView.fontColor.toString() === "white" || mainView.fontColor.toString() === "#ffffff"
                           ? "black" : "white"
                    border.color: "transparent"
                }
            }

            Row {
                width: parent.width
                topPadding: mainView.innerSpacing
                spacing: mainView.innerSpacing

                Button {
                    id: cancelButton
                    flat: true
                    padding: mainView.innerSpacing / 2
                    width: parent.width / 2 - mainView.innerSpacing / 2
                    text: qsTr("Cancel")

                    contentItem: Text {
                        text: cancelButton.text
                        color: mainView.fontColor
                        font.pointSize: mainView.mediumFontSize
                        horizontalAlignment: Text.AlignHCenter
                    }

                    background: Rectangle {
                        color: "transparent"
                        border.color: "gray"
                    }

                    onClicked: {
                        groupDialog.close()
                        groupNameField.text = ""
                    }
                }

                Button {
                    id: okButton
                    width: parent.width / 2 - mainView.innerSpacing / 2
                    padding: mainView.innerSpacing / 2
                    flat: true
                    text: qsTr("Ok")

                    contentItem: Text {
                        text: okButton.text
                        color: mainView.fontColor
                        font.pointSize: mainView.mediumFontSize
                        horizontalAlignment: Text.AlignHCenter
                    }

                    background: Rectangle {
                        color: "transparent"
                        border.color: "gray"
                    }

                    onClicked: {
                        if (groupNameField.text.trim().length > 0) {
                            if (groupDialog.groupName.length === 0) {
                                updateCustomGroupOfApp(groupDialog.app.package, groupNameField.text.trim())
                            } else {
                                updateCustomGroup(groupDialog.groupName, groupNameField.text.trim())
                            }
                            groupDialog.close()
                            groupNameField.text = ""
                        } else {
                            mainView.showToast(qsTr("Group name must have at least one character."))
                        }
                    }
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
            } else if (type === "volla.launcher.canDeleteAppResponce") {
               appContextMenu.canBeDeleted = message["canDeleteApp"]
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
        property string customGroups: ""

        function getCustomGroups() {
            if (settings.customGroups !== undefined && settings.customGroups.length > 0) {
                return JSON.parse(settings.customGroups)
            } else {
                return new Object
            }
        }

        function setCustomGroups(updatedCustomGroups) {
            settings.customGroups = JSON.stringify(updatedCustomGroups)
            settings.sync()
        }
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
