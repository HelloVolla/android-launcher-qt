import QtQuick 2.0
import QtQuick.Controls 2.5

MenuItem {
    id: appGridMenuItem

    property string appPackageName
    property double innerSpacing
    property double labelPointSize
    property double labelWidth

    anchors.margins: innerSpacing
    font.pointSize: labelPointSize
    contentItem: Label {
        width: labelWidth
        text: appGridMenuItem.text
        font: appGridMenuItem.font
        horizontalAlignment: Text.AlignHCenter
    }
    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }
    onClicked: {
        appGridMenuItem.parent.updateCustomGroups(appPackageName, text)
    }
}
