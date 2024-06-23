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
    height: 240
    width: 260
    padding: dialog.innerSpacing
    focus: true
    modal: true
    dim: false
    closePolicy: Popup.NoAutoClose

    property var fontSize
    property int innerSpacing

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
    }

    background: Item {
        anchors.fill: parent
        ShaderEffectSource {
            id: effectSource
            sourceItem: mainView
            anchors.fill: parent
            sourceRect: Qt.rect(dialog.x,dialog.y,dialog.width,dialog.height)
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

    contentItem: Column {
        //anchors.fill: parent
        width: dialog.width
        height: dialog.height
        spacing: dialog.innerSpacing
        Text {
            width: parent.width
            height: parent.height - buttonRow.height - dialog.innerSpacing
            text: qsTr("Now set up voice recognition for text input, which you can then activate using the microphone icon on the keyboard.")
            color: Universal.foreground
            wrapMode: Text.WordWrap
            font.pointSize: dialog.fontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        Row {
            id: buttonRow
            width: parent.width
            spacing: dialog.innerSpacing

            Button {
                id: cancelButton
                flat: true
                padding: dialog.innerSpacing / 2
                width: parent.width / 2 - dialog.innerSpacing / 2
                text: qsTr("Cancel")

                contentItem: Text {
                    text: cancelButton.text
                    color: Universal.foreground
                    font.pointSize: dialog.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }

                background: Rectangle {
                    color: "transparent"
                    border.color: "gray"
                }

                onClicked: {
                    dialog.close()
                }
            }

            Button {
                id: okButton
                width: parent.width / 2 - mainView.innerSpacing / 2
                padding: dialog.innerSpacing / 2
                flat: true
                text: qsTr("Ok")

                contentItem: Text {
                    text: okButton.text
                    color: Universal.foreground
                    font.pointSize: dialog.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }

                background: Rectangle {
                    color: "transparent"
                    border.color: "gray"
                }

                onClicked: {
                    AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": "com.volla.vollaboard"})
                    dialog.close()
                }
            }
        }
    }
}
