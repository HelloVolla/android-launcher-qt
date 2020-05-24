import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Universal 2.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN

CheckBox {
    id: settingsCheckbox

    property double labelFontSize
    property double circleSize
    property var actionId
    property bool checkedChanged: false

    width: parent.width
    text: qsTr("Chip")
    spacing: leftPadding / 2
    opacity: 0.0

    contentItem: Text {
        text: settingsCheckbox.text
        leftPadding: settingsCheckbox.indicator.width + settingsCheckbox.spacing
        font.pointSize: labelFontSize
        font.weight: Font.Normal
        color: Universal.foreground
        opacity: settingsCheckbox.checked ? 1.0 : 0.7
        verticalAlignment: Text.AlignVCenter
    }

    indicator: Rectangle {
        width: circleSize
        height: circleSize
        x: settingsCheckbox.leftPadding
        y: settingsCheckbox.height / 2 - circleSize / 2
        radius: width / 2
        color: settingsCheckbox.checked ? Universal.accent : Universal.foreground
        opacity: settingsCheckbox.checked ? 1.0 : 0.3
    }

    onVisibleChanged: {
        if (!visible) {
            console.log("Checkbox | Force visibility")
            visible = true
        }
    }

    onCheckedChanged: {
        if (!checkedChanged) {
            checkedChanged = !checkedChanged
            toast.show()
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

    AN.Toast {
        id: toast
        text: qsTr("Not yet supported")
        longDuration: true
    }
}
