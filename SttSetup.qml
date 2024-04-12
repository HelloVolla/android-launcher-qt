import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.2
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

Dialog {
    id: dialog
    anchors.centerIn: Overlay.overlay
    height: 200
    width: 250
    padding: popup.innerSpacing
    focus: true
    modal: true
    dim: false
    closePolicy: Popup.NoAutoClose
    standardButtons: Dialog.Ok | Dialog.Cancel

    property var fontSize
    property int innerSpacing

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
    }

    background: Item {
        ShaderEffectSource {
            id: effectSource
            sourceItem: mainView
            anchors.fill: parent
            sourceRect: Qt.rect(popup.x,popup.y,popup.width,popup.height)
        }
        FastBlur{
            id: blur
            anchors.fill: effectSource
            source: effectSource
            radius: 32
        }
        Rectangle {
            anchors.fill: parent
            color: "#2e2e2e"
            border.color: "transparent"
            opacity: 0.6
        }
    }

    contentItem: Text {
        text: qsTr("Setup speech to text")
        color: Universal.foreground
        wrapMode: Text.WordWrap
        font.pointSize: dialog.fontSize
    }

    onAccepted: {
        AN.SystemDispatcher.dispatch("volla.launcher.checkSttAvailability", {})
    }

    onRejected: {
        dialog.close()
    }
}
