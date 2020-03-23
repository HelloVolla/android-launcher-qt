import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.XmlListModel 2.13
import QtGraphicalEffects 1.12

import com.volla.launcher.backend 1.0

Page {
    id: appLauncher
    anchors.fill: parent

    property string textInput
    property real labelPointSize: 16
    property var iconMap: {"com.android.dialer": "/icons/dial-phone@4x.png",
        "com.google.android.apps.messaging": "/icons/message@4x.png",
        "com.google.android.apps.maps": "/icons/route-directions-map@4x.png",
        "com.android.camera2": "/icons/camera@4x.png",
        "com.google.android.apps.photos": "/icons/photo-gallery@4x.png",
        "com.android.contacts": "/icons/people-contacts-agenda@4x.png",
        "com.google.android.deskclock": "/icons/clock@4x.png",
        "com.android.settings": "/icons/settings@4x.png",
        "com.google.android.calendar": "/icons/calendar@4x.png",
        "com.android.documentsui": "/icons/folder@4x.png",
        "": "/icons/telegram@4x.png",
        "com.google.android.gm": "/icons/email@4x.png",
        "": "/icons/slack@4x.png",
        "": "/icons/notes@4x.png",
        "com.android.chrome": "/icons/browser@4x.png",
        "": "/icons/music@4x.png",
        "": "/icons/instagram@4x.png",
        "": "/icons/yalp-store@4x.png"}
    property var notificationMap: ["com.google.android.apps.messaging"]

    onTextInputChanged: {
        console.log("text input changed")
        gridModel.update(textInput)
        //xmlModel.update(textInput)
    }

    Component.onCompleted: {
        console.log("component completed")
        gridModel.loadModel()
    }

    GridView {
        id: gridView
        anchors.fill: parent
        cellHeight: parent.width * 0.32
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
                font.pointSize: swipeView.headerFontSize
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
                font.pointSize: swipeView.largeFontSize
                leftPadding: 0.0
                rightPadding: 0.0

                background: Rectangle {
                    color: "black"
                    border.color: "transparent"
                }
                Binding {
                    target: appLauncher
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
            bottomPadding: swipeView.innerSpacing / 2
        }

        delegate: Rectangle {
            id: gridCell
            width: parent.width * 0.25
            height: parent.width * 0.32
            color: "transparent"

            Rectangle {
                id: gridCircle
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.width * 0.6
                width: parent.width * 0.6
                color: "grey"
                opacity: 0.4
                radius: width * 0.5
            }

            Button {
                id: gridButton
                anchors.top: parent.top
                anchors.topMargin: parent.width * 0.08 // Adjustment
                width: parent.width
                text: model.label
                contentItem: Column {
                    spacing: gridCell.width * 0.25
                    Image {
                        id: buttonIcon
                        anchors.left: parent.left
                        anchors.leftMargin: gridCell.width * 0.25
                        source: model.package in appLauncher.iconMap ? Qt.resolvedUrl(appLauncher.iconMap[model.package]) : "data:image/png;base64," + model.icon
                        width: gridButton.width * 0.35
                        height: gridButton.width * 0.35
                    }
                    Label {
                        id: buttonLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: gridButton.width - swipeView.innerSpacing
                        horizontalAlignment: contentWidth > gridButton.width - swipeView.innerSpacing ? Text.AlignLeft : Text.AlignHCenter
                        text: gridButton.text
                        font.pointSize: appLauncher.labelPointSize
                        clip: true
                        color: Universal.foreground
                    }
                }
                flat:true
                onClicked: {
                    console.log("App " + model.label + " selected")
                    if (model.package.length > 0) {
                        backEnd.runApp(model.package)
                    }
                }
            }

            Desaturate {
                anchors.fill: gridButton
                source: gridButton
                desaturation: 1.0
            }

            LinearGradient {
                id: labelTruncator
                height: parent.height
                width: parent.width + parent.width * 0.2
                start: Qt.point(parent.width - 22,0)
                end: Qt.point(parent.width,0)
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#00000000"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#FF000000"
                    }
                }
            }

            Rectangle {
                id: notificationBadge
                visible: model.package in appLauncher.notificationMap
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
        xml: "" // backEnd.getApplist()
        query: "/root/item"

        XmlRole {
            name: "label"
            query: "label/string()"
        }
        XmlRole {
            name: "icon"
            query: "icon/string()"
        }
        XmlRole {
            name: "package"
            query: "package/string()"
        }

        onStatusChanged: {
            switch (status) {
                case XmlListModel.Null:
                    console.log("Xml model null")
                    break
                case XmlListModel.Ready:
                    console.log("Xml model ready")
                    log()
                    break
                case XmlListModel.Loading:
                    console.log("Xml model loading")
                    break
                case XmlListModel.Error:
                    console.log("Xml model error: " + errorString())
                    break
                default:
                    console.log("Xml model undefined")
            }
        }

        function update(text) {
            if (text.length > 0) {
                //query = "/root/item[substring(label,1," + text.length + ")='"+ text + "']"
                query = "/root/item[matches(label,'"+ text + "*','i')]"
            } else {
                query = "/root/item"
            }
        }

        function log() {
            console.log("Xml model listing:")

            for (var i = 0; i < xmlModel.count; i++) {
                var element = xmlModel.get(i)
                console.log(element.label + ": " + element.package)
            }
        }
    }

    BackEnd {
        id: backEnd
    }

    ListModel {
        id: gridModel

        property var modelArr: []

        function loadModel() {
            var jsonStr = backEnd.getApplistAsJSON()
            try {
                modelArr = JSON.parse(jsonStr)
                console.log("Grid model length: " + modelArr.length)
                console.log("Grid model sample: " + modelArr[0].label)
                update(textInput)
            } catch (e) {
                console.log("Grid model loading error: " + e)
            }
        }

        function update(text) {
            console.log("Update model with text input: " + text)

            var filteredGridDict = new Object
            var filteredGridItem
            var gridItem
            var found
            var i

            console.log("Model has " + modelArr.length + " elements")

            for (i = 0; i < modelArr.length; i++) {
                filteredGridItem = modelArr[i]
                var modelItemName = modelArr[i].label
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    //console.log("Add " + modelItemName + " to filtered items")
                    filteredGridDict[modelItemName] = filteredGridItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).label
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).label
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
                    console.log("Will append " + filteredGridItem.label)
                    append(filteredGridDict[modelItemName])
                }
            }
        }
    }
}
