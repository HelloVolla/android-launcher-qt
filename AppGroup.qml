import QtQuick 2.12
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
    property string messageApp
    property string phoneApp
    property string textInput

    property double innerSpacing
    property double labelPointSize
    property double backgroundOpacity
    property double desaturation: 1.0

    property int groupIndex
    property int selectedGroupIndex

    property bool unreadMessages: false
    property bool newCalls: false

    property var iconMap: new Object
    property var labelMap: new Object
    property var apps: new Array
    property var pinnedShortcuts: new Array

    onTextInputChanged: {
        console.log("AppGroup | onTextInputChanged")
        groupModel.update(groupItem.textInput)
    }

    onAppsChanged: {
        console.log("AppGroup | onAppsChanged")
        groupModel.clear()
        groupModel.modelArr = new Array
        groupModel.prepareModel()
        groupModel.update(groupItem.textInput)
    }

    onPinnedShortcutsChanged: {
        console.log("AppGroup | onPinnedShortcutsChanged")
//        groupModel.clear()
//        groupModel.modelArr = new Array
//        groupModel.prepareModel()
//        groupModel.update(groupItem.textInput)
    }

    onDesaturationChanged: {
        groupGrid.forceLayout()
    }

    onSelectedGroupIndexChanged: {
        groupGrid.visible = groupIndex === selectedGroupIndex
    }

    function showApps(appsShouldBeVisible) {
        groupGrid.visible = appsShouldBeVisible
    }

    function removePinnedShortcut(shorcutId) {
        pinnedShortcuts = pinnedShortcuts.filter(function(item) {
            return item.itemId !== shorcutId
        })
        groupModel.prepareModel()
        groupModel.update(textInput)
    }

    Column {
        id: groupColumn
        width: parent.width

        Button {
            id: groupHeader
            anchors.horizontalCenter: parent.horizontalCenter
            flat: true
            text: groupItem.groupLabel
            visible: groupItem.groupIndex > 0

            onClicked: {
                parent.showGroup(groupItem.groupIndex)
            }
        }

        GridView {
            id: groupGrid
            width: parent.width
            height: contentHeight
            cellHeight: parent.width * 0.32
            cellWidth: parent.width * 0.25
            visible: true // groupItem.groupIndex === groupItem.selectedGroupIndex

//            Component.onCompleted: {
//                console.log("AppGroup | GridView is Ready")
//                groupModel.prepareModel()
//                groupModel.update(groupItem.textInput)
//            }

            model: groupModel

            currentIndex: -1

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
                            source: model.package in groupItem.iconMap && model.shortcutId === undefined
                                    ? Qt.resolvedUrl(groupItem.iconMap[model.package]) : "data:image/png;base64," + model.icon
                            width: gridButton.width * 0.35
                            height: gridButton.width * 0.35

                            ColorOverlay {
                                anchors.fill: buttonIcon
                                source: buttonIcon
                                color: gridCell.overlayColor
                                visible: (model.package in groupItem.iconMap) && model.shortcutId === undefined
                            }
                        }
                        Label {
                            id: buttonLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: gridButton.width - groupItem.innerSpacing
                            horizontalAlignment: contentWidth > gridButton.width - mainView.innerSpacing ? Text.AlignLeft : Text.AlignHCenter
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
                            parent.closeContextMenu()
                            groupGrid.currentIndex = -1
                        } else if (model.package.length > 0) {
                            console.log("App " + model.label + " selected")
                            // As a workaround for a missing feature in the phone app
                            if (model.package === mainView.phoneApp) {
                                if (groupItem.newCalls) {
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
                        groupGrid.currentIndex = index
                        parent.openContextMenu(model, gridCell)
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
                                                                          : model.package === groupItem.phoneApp ? groupItem.newCalls                                                               : false
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

        ListModel {
            id: groupModel

            property var modelArr: new Array

            // Call this method, if apps or shortcuts habe been changed
            function prepareModel() {
                modelArr = groupItem.pinnedShortcuts.concat(groupItem.apps)
                modelArr.forEach(function(app, i) {
                    modelArr[i].label = app.package in groupItem.labelMap && app.shortcutId === undefined
                            ? qsTr(groupItem.labelMap[app.package]) : app.label
                    modelArr[i].itemId = app.shortcutId !== undefined ? app.shortcutId : app.package
                })
            }

            // Call this method to update the grid content
            function update(text) {
                console.log("AppGroup | Update model with text input: " + text)

                var filteredGridDict = new Object
                var filteredGridItem
                var gridItem
                var found
                var i

                console.log("AppGroup | Model " + groupItem.groupLabel + " has " + modelArr.length + " elements")

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
                        console.log("AppGroup | Will append " + key)
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
        }

        Connections {
            target: AN.SystemDispatcher
            onDispatched: {
                if (type === "volla.launcher.callLogResponse") {
                    console.log("AppGrid | Missed calls: " + message["callsCount"])
                    groupItem.newCalls = message["callsCount"] > 0
                } else if (type === "volla.launcher.threadsCountResponse") {
                    console.log("AppGrid | Unread messages: " + message["threadsCount"])
                    groupItem.unreadMessages = message["threadsCount"] > 0
                }
            }
        }
    }
}
