import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.2
import QtQuick.Controls.Universal 2.12

Popup {
    id: popup
    anchors.centerIn: Overlay.overlay
    height: Screen.height * 0.3
    width: Screen.width - 2 * innerSpacing
    padding: innerSpacing
    focus: true
    modal: true
    dim: false
    closePolicy: Popup.CloseOnPressOutside

    property var mainView
    property int innerSpacing

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
    }

    background: Rectangle {
        anchors.fill: parent
        color: "darkslategrey"
        opacity: 0.8
        radius: innerSpacing
        border.color: "transparent"
    }

    contentItem: SwipeView {
        id: view
        anchors.fill: popup
        padding: innerSpacing

        Timer {
            id: timer
        }

        function delay(delayTime) {
            timer.interval = delayTime
            timer.repeat = false
            timer.start()
        }

        Item {
            id: smartTextfield

            property var dummyContacts: [ {"name": "Peter"} ]

            Column {
                width: parent.width - (2 * innerSpacing)
                spacing: innerSpacing

                Label {
                    id:label
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Start writing and get suggestions for completion and functions")
                    wrapMode: Text.WordWrap
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Button {
                    text: qsTr("Show")
                    anchors.horizontalCenter: parent.horizontalCenter

                    onPressed: {
                        if (text === qsTr("Show")) {
                            mainView.contacts = smartTextfield.dummyContacts
                            mainView.updateSpringboard("@")
                            view.delay(1000)

                            label.text = qsTr("Learn about more use cases in the printed manual")
                            text = qsTr("Next")
                        } else {
                            view.currentIndex = view.currentIndex++
                        }
                    }
                }
            }
        }

        Item {
            id: redDotMenu

            Column {
                width: parent.width - (2 * innerSpacing)

                Label {
                    width: parent.width
                    text: qsTr("Touch the red dot, drag to a menu item and release for your selection.")
                    wrapMode: Text.WordWrap
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Button {
                    text: qsTr("Show")
                    anchors.horizontalCenter: parent.horizontalCenter

                    onPressed: {
                        if (text === qsTr("Show")) {

                            text = qsTr("Next")
                        } else {
                            view.currentIndex = view.currentIndex++
                        }
                    }
                }
            }
        }

        Item {
            id: smartCollections

            Column {
                width: parent.width - (2 * innerSpacing)

                Label {
                    width: parent.width
                    text: qsTr("Use smart content collections for recent contacts, messages, news and notes")
                    wrapMode: Text.WordWrap
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Button {
                    text: qsTr("Show")
                    anchors.horizontalCenter: parent.horizontalCenter

                    onPressed: {
                        if (text === qsTr("Show")) {

                            text = qsTr("Next")
                        } else {
                            view.currentIndex = view.currentIndex++
                        }
                    }
                }
            }
        }

        Item {
            id: appOverview

            Column {
                width: parent.width - (2 * innerSpacing)

                Label {
                    width: parent.width
                    text: qsTr("Swipe to the right to see the app overview")
                    wrapMode: Text.WordWrap
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Button {
                    text: qsTr("Show")
                    anchors.horizontalCenter: parent.horizontalCenter

                    onPressed: {
                        if (text === qsTr("Show")) {
                            popup.mainView.currentIndex = 1
                            text = qsTr("Next")
                        } else {
                            view.currentIndex = view.currentIndex++
                        }
                    }
                }
            }
        }

        Item {
            id: launcherSettings

            Column {
                width: parent.width - (2 * innerSpacing)

                Label {
                    width: parent.width
                    text: qsTr("Swipe to the right to see the launcher settings")
                    wrapMode: Text.WordWrap
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Button {
                    text: qsTr("Show")
                    anchors.horizontalCenter: parent.horizontalCenter

                    onPressed: {
                        if (text === qsTr("Show")) {
                            popup.mainView.currentIndex = 0
                            text = qsTr("Finish")
                        } else {
                            popup.mainView.currentIndex = 2
                            popup.close()
                        }
                    }
                }
            }
        }
    }

    PageIndicator {
        id: indicator

        count: view.count
        currentIndex: view.currentIndex

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
}
