import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.XmlListModel 2.13
import com.volla.launcher.backend 1.0

Page {
    id: appGrid
    anchors.fill: parent

    property string textInput
    property real labelPointSize: 16

    onTextInputChanged: {
        console.log("text input changed")
        gridModel.update(textInput)
    }

    Component.onCompleted: {
        gridModel.update("")
        xmlModel.log()
    }

    GridView {
        id: gridView
        anchors.fill: parent
        cellHeight: parent.width * 0.3
        cellWidth: parent.width * 0.25

        model: gridModel

        header: Column {
            id: header
            width: parent.width
            Label {
                id: headerLabel
                topPadding: swipeView.innerSpacing
                x: swipeView.innerSpacing
                text: qsTr("Apps")
                font.pointSize: swipeView.headerPointSize
                font.weight: Font.Black
            }
            TextField {
                id: textField
                padding: swipeView.innerSpacing
                x: swipeView.innerSpacing
                width: parent.width - swipeView.innerSpacing * 2
                placeholderText: qsTr("Filter apps")
                color: Universal.foreground
                placeholderTextColor: "darkgrey"
                font.pointSize: swipeView.pointSize
                leftPadding: 0.0
                rightPadding: 0.0

                background: Rectangle {
                    color: "black"
                    border.color: "transparent"
                }
                Binding {
                    target: appGrid
                    property: "textInput"
                    value: textField.displayText.toLowerCase()
                }
            }
            Rectangle {
                width: parent.width
                border.color: Universal.background
                color: "transparent"
                height: 1.1
            }
        }

        delegate: Rectangle {
            anchors.topMargin: swipeView.innerSpacing
            anchors.bottomMargin: swipeView.innerSpacing * 2

            width: parent.width * 0.25
            height: parent.width * 0.5
            color: "transparent"

            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.width * 0.6
                width: parent.width * 0.6
                color: "grey"
                opacity: 0.4
                radius: width * 0.5
            }

            Button {
                anchors.top: parent.top
                anchors.topMargin: parent.width * 0.1
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: parent.width * 0.2
                text: model.gridName
                font.pointSize: appGrid.labelPointSize
                flat:true
                icon.source: Qt.resolvedUrl(model.icon)
                icon.width: parent.width * 0.35
                icon.height: parent.width * 0.35
                display: AbstractButton.TextUnderIcon
                onClicked: {
                    console.log("App " + model.gridName + " selected")
                    //Qt.openUrlExternally(model.source)
                    if (model.source.length > 0) {
                        backEnd.runApp(model.source)
                    }
                }
            }

            Rectangle {
                visible: model.notification === true
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: (parent.width - parent.width * 0.6) * 0.5
                width: parent.width * 0.15
                height: parent.width * 0.15
                radius: height * 0.5
                color: Universal.accent
            }
        }
    }

    XmlListModel {
        id: xmlModel
        query: "/root/item"

        XmlRole { name: "name"; query: "name/string()" }
        XmlRole { name: "path"; query: "path/string()" }

        function log() {
            console.log("Print model")
            xmlModel.xml = backEnd.getApplist();
            //console.log("XML: " + xmlModel.xml)

            for (var i = 0; i < count; i++) {
                var element = get(i)
                console.log(element.name + ": " + element.path)
            }
        }
    }

    BackEnd {
        id: backEnd
    }

    ListModel {
        id: gridModel

        property var modelArr: [{"gridName": "Dialer", "notification" : false, "source": "com.google.android.dialer", "icon": "/icons/dial-phone@4x.png"},
                                {"gridName": "Messanger", "notification" : true, "source": "com.google.android.apps.messaging", "icon": "/icons/message@4x.png"},
                                {"gridName": "Maps", "notification" : false, "source": "com.google.android.apps.maps", "icon": "/icons/route-directions-map@4x.png"},
                                {"gridName": "Camera", "notification" : false, "source": "com.android.camera2", "icon": "/icons/camera@4x.png"},
                                {"gridName": "Gallery", "notification" : false, "source": "com.google.android.apps.photos", "icon": "/icons/photo-gallery@4x.png"},
                                {"gridName": "People", "notification" : false, "source": "com.android.contacts", "icon": "/icons/people-contacts-agenda@4x.png"},
                                {"gridName": "Clock", "notification" : false, "source": "com.google.android.deskclock", "icon": "/icons/clock@4x.png"},
                                {"gridName": "Settings", "notification" : false, "source": "com.android.settings", "icon": "/icons/settings@4x.png"},
                                {"gridName": "Calendar", "notification" : false, "source": "com.google.android.calendar", "icon": "/icons/calendar@4x.png"},
                                {"gridName": "Files", "notification" : false, "source": "com.android.documentsui", "icon": "/icons/folder@4x.png"},
                                {"gridName": "Telegram", "notification" : false, "source": "", "icon": "/icons/telegram@4x.png"},
                                {"gridName": "Email", "notification" : true, "source": "com.google.android.gm", "icon": "/icons/email@4x.png"},
                                {"gridName": "Slack", "notification" : false, "source": "", "icon": "/icons/slack@4x.png"},
                                {"gridName": "Notes", "notification" : false, "source": "", "icon": "/icons/notes@4x.png"},
                                {"gridName": "Browser", "notification" : false, "source": "com.android.chrome", "icon": "/icons/browser@4x.png"},
                                {"gridName": "Music", "notification" : false, "source": "", "icon": "/icons/music@4x.png"},
                                {"gridName": "Instagram", "notification" : false, "source": "", "icon": "/icons/instagram@4x.png"},
                                {"gridName": "Yalp", "notification" : false, "source": "", "icon": "/icons/yalp-store@4x.png"}]


        function update(text) {
            console.log("Update model with text input: " + text)

            var filteredGridDict = new Object
            var filteredGridItem
            var gridItem
            var found
            var i

            console.log("Model: " + modelArr)

            for (i = 0; i < modelArr.length; i++) {
                filteredGridItem = modelArr[i]
                var modelItemName = modelArr[i].gridName
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Add " + modelItemName + " to filtered items")
                    filteredGridDict[modelItemName] = filteredGridItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).gridName
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).gridName
                found = filteredGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            for (modelItemName in filteredGridDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredGridItem = filteredGridDict[modelItemName]
                    console.log("Will append " + filteredGridItem.gridName)
                    append(filteredGridDict[modelItemName])
                }
            }
        }
    }
}
