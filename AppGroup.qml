import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN
import FileIO 1.0

Item {
    id: groupItem
    width: parent.width
    implicitHeight: groupColumn.height

    property string groupLabel
    property var messageApp
    property string phoneApp
    property string textInput: ""

    property double innerSpacing
    property double componentSpacing
    property double labelPointSize
    property double headerPointSize
    property double backgroundOpacity
    property double desaturation: 1.0
    property int groupIndex: 0
    property int selectedGroupIndex: 1
    property int columnCount: Screen.desktopAvailableWidth < 521 ? 4 : Screen.desktopAvailableWidth > 800 ? 8 : 5

    property bool unreadMessages: false
    property bool newCalls: false
    property bool isHeaderVisible: groupIndex !== selectedGroupIndex
    property bool isHeader2Visible: groupIndex === selectedGroupIndex && groupIndex > 0 && groupLabel.toLowerCase()
    property bool isGridVisible: groupIndex === selectedGroupIndex

    property var accentColor
    property var notificationData:""
    property var iconMap: ({})
    property var labelMap: ({})
    property var apps: []
    property var pinnedShortcuts: []

    Component.onCompleted: {
        console.debug("AppGroup | Screen width: " + Screen.desktopAvailableWidth)
        columnCount = Screen.desktopAvailableWidth < 446 ? 4 : Screen.desktopAvailableWidth > 800 ? 8 : 5
    }

    onWidthChanged: {
        console.log("AppGroup | Width changed to " + width)
        if (width > 820) {
            columnCount = 8
        } else {
            columnCount = 5
        }
    }

    onTextInputChanged: {
        console.log("AppGroup " + groupIndex + " | onTextInputChanged")
        groupModel.update(groupItem.textInput)
    }

    onAppsChanged: {
        console.log("AppGroup " + groupIndex + " | onAppsChanged: " + groupItem.apps.length)
        groupModel.prepareModel()
    }

    onPinnedShortcutsChanged: {
        console.log("AppGroup " + groupIndex + " | onPinnedShortcutsChanged")
        console.debug("AppGroup " + groupIndex + " | Number of pinned shortcuts: " + groupItem.pinnedShortcuts.length)
        groupModel.prepareModel()
    }

    onDesaturationChanged: {
        console.log("AppGroup " + groupIndex + " | onDesaturationChanged to " + desaturation)
        groupGrid.forceLayout()
    }

    onBackgroundOpacityChanged: {
        groupGrid.forceLayout()
    }

    onSelectedGroupIndexChanged: {
        console.log("AppGroup " + groupIndex + " | Selected group changed to " + selectedGroupIndex)
        groupColumn.topPadding = groupItem.groupIndex === 0 ? 0 : groupItem.groupIndex === 1 && groupItem.selectedGroupIndex === 0 ? groupItem.innerSpacing / 2 : groupItem.innerSpacing
    }

    function showApps(appsShouldBeVisible) {
        groupGrid.visible = appsShouldBeVisible
        groupHeader.visible = !appsShouldBeVisible
    }

    function removePinnedShortcut(shortcutId) {
        if (groupItem.groupIndex === 0) {
            groupItem.pinnedShortcuts = groupItem.pinnedShortcuts.filter(function(item) {
                return item.shortcutId !== shortcutId
            })
        }
    }

    Column {
        id: groupColumn
        width: parent.width
        topPadding: groupItem.groupIndex === 0 ? 0 : groupItem.groupIndex === 1 && groupItem.selectedGroupIndex === 0 ?
                                                     groupItem.componentSpacing / 2 : groupItem.componentSpacing
        Button {
            id: groupHeader
            visible: groupItem.isHeaderVisible
            anchors.horizontalCenter: parent.horizontalCenter
            flat: true
            text: groupItem.groupLabel
            contentItem: Label {
                text: groupHeader.text
                padding: groupItem.innerSpacing / 2
                color: Universal.foreground
                opacity: 0.5
                font.pointSize: groupItem.headerPointSize
            }
            background: Rectangle {
                color: "transparent"
                border.color: Universal.foreground
                opacity: 0.5
                radius: height / 2
            }

            onClicked: {
                groupItem.parent.showGroup(groupItem.groupIndex)
            }
        }

        Label {
            id: groupHeader2
            visible: groupItem.isHeader2Visible
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: groupItem.componentSpacing / 2
            bottomPadding: groupItem.componentSpacing / 2
            leftPadding: groupItem.innerSpacing / 2
            rightPadding: groupItem.innerSpacing / 2
            text: groupHeader.text
            color: Universal.foreground
            opacity: 0.5
            font.pointSize: groupItem.labelPointSize
            background: Rectangle {
                color: "transparent"
                border.color: "transparent"
            }
        }

        GridView {
            id: groupGrid
            width: parent.width
            height: contentHeight
            cellHeight: parent.width / groupItem.columnCount * 1.28
            cellWidth: parent.width / groupItem.columnCount
            visible: groupItem.isGridVisible
            interactive: false

            model: groupModel

            currentIndex: -1

            delegate: Rectangle {
                id: gridCell
                width: groupGrid.cellWidth
                height: groupGrid.cellHeight
                color: "transparent"

                property var gradientColor: Universal.background
                property var overlayColor: Universal.foreground

                Rectangle {
                    id: gridCircle
                    anchors.top: gridButton.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: parent.width * 0.55
                    width: parent.width * 0.55
                    color: Universal.foreground
                    opacity: Universal.theme === Universal.Light ? 0.1 : 0.2
                    radius: width * 0.5
                }

                Button {
                    id: gridButton
                    anchors.top: parent.top
                    anchors.centerIn: gridCell
                    topPadding: (gridCircle.height - buttonIcon.height) / 2 //groupItem.innerSpacing / 2
                    width: parent.width
                    text: model.label
                    contentItem: Column {
                        spacing: gridCell.width * 0.25
                        Image {
                            id: buttonIcon
                            anchors.horizontalCenter: parent.horizontalCenter
                            //anchors.left: parent.left
                            //anchors.leftMargin: gridCell.width * 0.25
                            source: model.package in groupItem.iconMap && (model.shortcutId === undefined || model.shortcutId.length === 0) && desaturation === 1.0
                                    ? Qt.resolvedUrl(groupItem.iconMap[model.package]) : "data:image/png;base64," + model.icon
                            width: gridButton.width * 0.35
                            height: gridButton.width * 0.35
                            cache: false

                            ColorOverlay {
                                anchors.fill: buttonIcon
                                source: buttonIcon
                                color: gridCell.overlayColor
                                visible: (model.package in groupItem.iconMap) && model.shortcutId === undefined && desaturation === 1.0
                            }
                        }
                        Label {
                            id: buttonLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: gridButton.width - groupItem.innerSpacing
                            horizontalAlignment: contentWidth > gridButton.width - groupItem.innerSpacing ? Text.AlignLeft
                                                                                                          : Text.AlignHCenter
                            text: gridButton.text
                            font.pointSize: groupItem.labelPointSize
                            clip: groupItem.backgroundOpacity === 1.0 ? true : false
                            elide: groupItem.backgroundOpacity === 1.0 ? Text.ElideNone :  Text.ElideRight
                        }
                    }
                    flat:true
                    background: Rectangle {
                        color: "transparent"
                        border.color: "transparent"
                    }
                    onClicked: {
                        if (groupGrid.currentIndex > -1) {
                            groupItem.parent.closeContextMenu()
                            groupGrid.currentIndex = -1
                        } else if (model.package.length > 0) {
                            console.log("App Group | App " + model.label + " selected")
                            // As a workaround for a missing feature in the phone app
                            if (model.package === groupItem.phoneApp) {
                                if (groupItem.newCalls) {
                                    AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": groupItem.phoneApp, "action": "log"})
                                    AN.SystemDispatcher.dispatch("volla.launcher.updateCallsAsRead", { })
                                } else {
                                    AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": groupItem.phoneApp})
                                }
                            } else if (model.shortcutId !== undefined && model.shortcutId.length > 0) {
                                AN.SystemDispatcher.dispatch("volla.launcher.launchShortcut",
                                                             {"shortcutId": model.shortcutId, "package": model.package})
                            } else {
                                AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": model.package})
                            }
                             AN.SystemDispatcher.dispatch("volla.launcher.clearRedDot", {"package": model.package})
                        }
                    }
                    onPressAndHold: {
                        groupGrid.currentIndex = index
                        groupItem.parent.openContextMenu(model, gridCell, groupGrid)
                    }
                }

                Desaturate {
                    anchors.fill: gridButton
                    source: gridButton
                    desaturation: groupItem.desaturation
                }

                LinearGradient {
                    id: labelTruncator
                    height: parent.height
                    width: parent.width
                    start: Qt.point(parent.width - groupItem.innerSpacing, 0)
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
                    visible: groupItem.backgroundOpacity === 1.0
                }

                Rectangle {
                    id: notificationBadge
                    visible: groupItem.messageApp.includes(model.package) ? groupItem.unreadMessages
                                                                          : model.package === groupItem.phoneApp ? groupItem.newCalls
                                                                          : groupItem.notificationData.hasOwnProperty(model.package) ? true : false
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 6.0
                    anchors.leftMargin: (parent.width - parent.width * 0.6) * 0.5
                    width: parent.width * 0.15
                    height: parent.width * 0.15
                    radius: height * 0.5
                    color:  accentColor
                }
            }

            Behavior on contentHeight {
                NumberAnimation {
                    duration: 250.0
                }
            }
        }

        WorkerScript {
            id: groupModelWorker
            source: "scripts/apps.mjs"

            property bool isReady: false

            onMessage: {
                console.debug("AppGroup " + groupIndex + " | Worker message received")
                groupModel.modelArr = messageObject.apps
                groupHeader.text = groupLabel.toLowerCase() === "apps"  ? "+" + groupModel.count + " " + groupLabel : groupLabel
                groupItem.visible = groupModel.count > 0
            }
            Component.onCompleted: {
                console.debug("AppGroup " + groupIndex + " | Workerscript established" );
                isReady = true
                if (groupModel.pendingMessage !== undefined) {
                    console.debug("AppGroup " + groupIndex + " | Will send message to Workerscript" );
                    sendMessage(groupModel.pendingMessage)
                }
            }
        }

        ListModel {
            id: groupModel

            property var modelArr: new Array
            property var pendingMessage

            onCountChanged: {
                console.log("AppGroup " + groupIndex + " | Number of grid itens changed: " + count)
            }

            // Call this method, if apps or shortcuts have been changed
            function prepareModel() {
                console.debug("AppGroup " + groupIndex + " | Will prepare model")
                if (groupModelWorker.isReady) {
                    console.debug("AppGroup " + groupIndex + " | Will send worker message")
                    groupModelWorker.sendMessage({
                        "apps": groupItem.pinnedShortcuts.concat(groupItem.apps),
                        "labelMap" : groupItem.labelMap,
                        "model" : groupModel,
                        "text" : groupItem.textInput
                    })
                } else {
                    console.debug("AppGroup " + groupIndex + " | Will define pending message for script status " + groupModelWorker.status)
                    pendingMessage = {
                        "apps": groupItem.pinnedShortcuts.concat(groupItem.apps),
                        "labelMap" : groupItem.labelMap,
                        "model" : groupModel,
                        "text" : groupItem.textInput
                    }
                }
            }

            // Call this method to update the grid content
            function update(text) {
                console.log("AppGroup " + groupIndex + " | Update model with text input: " + text)

                var filteredGridDict = new Object
                var filteredGridItem
                var gridItem
                var found
                var i

                console.log("AppGroup " + groupIndex + " | Model '" + groupItem.groupLabel + "' has " + modelArr.length + " elements")
                console.log("AppGroup " + groupIndex + " | Model '" + groupItem.groupLabel + "' has " + count + " elements")

                // filter model
                for (i = 0; i < modelArr.length; i++) {
                    filteredGridItem = modelArr[i]
                    var modelItemName = modelArr[i].label
                    var modelItemId = modelArr[i].itemId
                    if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
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
                        console.log("AppGrop | Remove " + modelItemId)
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
                        console.debug("AppGroup " + groupIndex + " | * Will append " + key)
                        append(filteredGridItem)
                    }
                })

                groupHeader.text = groupLabel.toLowerCase() === "apps"  ? "+" + count + " " + groupLabel : groupLabel
                groupItem.visible = count > 0
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
        }

        Connections {
            target: AN.SystemDispatcher
            onDispatched: {
                if (type === "volla.launcher.callCountResponse") {
                    console.log("AppGroup " + groupIndex + " | Missed calls: " + message["callsCount"])
                    groupItem.newCalls = message["callsCount"] > 0
                } else if (type === "volla.launcher.threadsCountResponse") {
                    console.log("AppGroup " + groupIndex + " | Unread messages: " + message["threadsCount"])
                    groupItem.unreadMessages = message["threadsCount"] > 0
                } else if(type === "volla.launcher.otherAppNotificationResponce") {
                    groupItem.notificationData = message["Notification"]
                }
            }
        }
    }
}
