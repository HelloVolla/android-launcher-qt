import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Universal 2.12

Label {
    id: shortCut
    font.pointSize: labelFontSize
    anchors.left: parent.left
    anchors.right: parent.right
    color: mainView.accentTextColor
    elide: Text.ElideRight
    wrapMode: Text.NoWrap
    horizontalAlignment: settings.leftHandedMenu ? Text.AlignLeft : Text.AlignLeft

    property var actionId
    property double labelFontSize
}
