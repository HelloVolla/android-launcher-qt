import QtQuick 2.0
import QtQuick.Controls 2.5

MenuItem {
    id: appGridMenuItem

    property var appLauncher
    property string appId
    property string appGroup
    property string fontFamilyName
    property double innerSpacing
    property double labelPointSize
    property double labelWidth

    anchors.margins: innerSpacing
    font.pointSize: labelPointSize
    font.family: fontFamilyName
    contentItem: Label {
        width: appGridMenuItem.labelWidth
        text: appGridMenuItem.appGroup === "AAAA" ? "★ " + qsTr("Add to ") + qsTr("Favorits") : qsTr("Add to ") + appGridMenuItem.appGroup
        font: appGridMenuItem.font
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }
    onClicked: {
        appLauncher.updateCustomGroupOfApp(appId, appGroup)
    }
}
