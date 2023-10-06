import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Universal 2.12

Button {
    id: settingsButton

    property bool boldText: false
    property alias textColor: buttonText.color
    property alias textOpacity: buttonText.opacity
    property alias backgroundColor: buttonBackground.color
    property alias fontPointSize: buttonText.font.pointSize

    padding: mainView.innerSpacing
    contentItem: Text {
        id: buttonText
        width: parent.width - 2 * settingsButton.padding
        font.pointSize: mainView.largeFontSize
        font.weight: settingsButton.boldText ? Font.Black : Font.Normal
        text: settingsButton.text
        color: Universal.foreground
    }
    background: Rectangle {
        id: buttonBackground
        anchors.fill: parent
        color: "transparent"
    }
}