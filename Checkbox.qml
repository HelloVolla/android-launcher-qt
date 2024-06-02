import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Universal 2.12

CheckBox {
    id: settingsCheckbox

    property double labelFontSize
    property double circleSize
    property var actionId
    property bool activeCheckbox: false
    property bool hasRemoveButton: false
    property bool hasDescriptionButton: false
    property bool isToggle: false
    property int startX: 0
    property var accentColor

    width: parent.width
    text: qsTr("Chip")
    spacing: leftPadding / 2
    opacity: 0.0

    contentItem: Text {
        text: settingsCheckbox.text
        elide: Text.ElideRight
        width: parent.width - leftPadding * 2 - removeButton.width
        leftPadding: settingsCheckbox.indicator.width + settingsCheckbox.spacing
        font.pointSize: labelFontSize
        font.weight: Font.Normal
        color: Universal.foreground
        opacity: settingsCheckbox.checked ? 1.0 : 0.7
        verticalAlignment: Text.AlignVCenter
    }

    Button {
        id: removeButton
        anchors.right: parent.right
        rightPadding: settingsCheckbox.leftPadding
        leftPadding: settingsCheckbox.leftPadding
        flat: true
        text: "<font color='#808080'>×</font>"
        font.pointSize: labelFontSize
        onClicked: {
            console.log("Checkbox | Remove item from settings: " + settingsCheckbox.text)
            settingsCheckbox.parent.removeSettings(actionId)
        }
        visible: settingsCheckbox.hasRemoveButton
    }

    Button {
        id: descriptionButton
        anchors.right: parent.right
        rightPadding: settingsCheckbox.leftPadding
        leftPadding: settingsCheckbox.leftPadding
        flat: true
        text: "<font color='#808080'>ⓘ</font>"
        font.pointSize: labelFontSize
        onClicked: {
            console.log("Checkbox | Show description: " + settingsCheckbox.text)
            settingsCheckbox.parent.showDescription(actionId)
        }
        visible: settingsCheckbox.hasDescriptionButton
    }

    indicator: Rectangle {
        width: circleSize
        height: circleSize
        x: settingsCheckbox.leftPadding
        y: settingsCheckbox.height / 2 - circleSize / 2
        radius: width / 2
        color: settingsCheckbox.checked ? accentColor : Universal.foreground
        opacity: settingsCheckbox.checked ? 1.0 : 0.3
    }

    onVisibleChanged: {
        if (!visible) {
            console.log("Checkbox | Force visibility")
            visible = true
        }
    }

    onCheckedChanged: {
        console.log("Checkbox | Checked changed for " + text + ", " + checked)
        if (activeCheckbox) {
            if (isToggle && !checked) {
                activeCheckbox = false
                checked = true
            } else {
                parent.updateSettings(actionId, checked)
            }
        }
    }

    Component.onCompleted: {
        opacity = 1.0
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 250
        }
    }
}
