import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.2
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12


Popup {
    id: popup
    anchors.centerIn: Overlay.overlay
    height: Screen.height * 0.3
    width: Screen.width
    focus: true
    modal: true
    dim: false
    closePolicy: Popup.NoAutoClose

    property var mainView
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

    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.triggered.connect(function release () {
                timer.triggered.disconnect(cb); // This is important
                timer.triggered.disconnect(release); // This is important as well
            });
            timer.start();
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 0
        interactive: true
        topPadding: popup.innerSpacing

        Item {
            Label {
                id: label1
                width: parent.width
                padding: popup.innerSpacing
                text: qsTr("Start writing and get suggestions for completion and functions")
                wrapMode: Text.WordWrap
                font.pointSize: mainView.mediumFontSize
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                id: button1
                anchors.top: label1.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Show demo")
                font.pointSize: mainView.mediumFontSize
                onClicked: {
                    if (text === qsTr("Show demo")) {
                        enabled = false
                        swipeView.showTextfieldDemo()
                    } else {
                        swipeView.currentIndex = 1
                    }
                }
            }
        }

        Item {
            Label {
                id: label2
                width: parent.width
                padding: popup.innerSpacing
                text: qsTr("Touch the red dot, drag to a menu item and release for your selection.")
                wrapMode: Text.WordWrap
                font.pointSize: mainView.mediumFontSize
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                id: button2
                anchors.top: label2.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Show demo")
                font.pointSize: mainView.mediumFontSize
                onClicked: {
                    if (text === qsTr("Show demo")) {
                        enabled = false
                        swipeView.showRedDotDemo()
                    } else {
                        swipeView.currentIndex = 2
                    }
                }
            }
        }

        Item {
            Label {
                id: label3
                width: parent.width
                padding: popup.innerSpacing
                text: qsTr("Use smart content collections for recent contacts, messages, news and notes")
                wrapMode: Text.WordWrap
                font.pointSize: mainView.mediumFontSize
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                id: button3
                anchors.top: label3.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Show demo")
                font.pointSize: mainView.mediumFontSize
                onClicked: {
                    console.debug("OnBoarding | Text " + text)
                    if (text === qsTr("Show demo")) {
                        enabled = false
                        swipeView.showCollectionDemo()
                    } else {
                        swipeView.currentIndex = 3
                    }
                }
            }
        }

        Item {
            Label {
                id: label4
                width: parent.width
                padding: popup.innerSpacing
                text: qsTr("Swipe to the right to see the app overview")
                wrapMode: Text.WordWrap
                font.pointSize: mainView.mediumFontSize
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                id: button4
                anchors.top: label4.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Show demo")
                font.pointSize: mainView.mediumFontSize
                onClicked: {
                    if (text === qsTr("Show demo")) {
                        popup.mainView.currentIndex = 1
                        text = qsTr("Next hint")
                    } else {
                        swipeView.currentIndex = 4
                    }
                }
            }
        }

        Item {
            Label {
                id: label5
                width: parent.width
                padding: popup.innerSpacing
                text: qsTr("Swipe to the right to see the launcher settings")
                wrapMode: Text.WordWrap
                font.pointSize: mainView.mediumFontSize
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                id: button5
                anchors.top: label5.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Show demo")
                font.pointSize: mainView.mediumFontSize
                onClicked: {
                    if (text === qsTr("Show demo")) {
                        popup.mainView.currentIndex = 0
                        text = qsTr("Finish")
                    } else {
                        popup.mainView.currentIndex = 2
                        popup.close()
                    }
                }
            }
        }

        function showTextfieldDemo() {
            var dummyContacts = [ {"name": "Peter Pan", "phone.mobile": "000000", "email.work": "ooo@ooo.de"},
                                  {"name": "Lisa Summer", "phone.mobile": "000000", "email.home": "ooo@ooo.de"},
                                  {"name": "Marc Aurel", "phone.mobile": "000000", "email.home": "ooo@ooo.de"}]

            mainView.contacts = dummyContacts
            mainView.updateSpringboard("@")

            timer.setTimeout(function() {
                mainView.updateSpringboard("@p")

                timer.setTimeout(function() {
                    mainView.updateSpringboard("@Peter_Pan ", dummyContacts[0])

                    timer.setTimeout(function() {
                        mainView.updateSpringboard("@Peter_Pan " + qsTr("Hello World") + "!")

                        timer.setTimeout(function() {
                            mainView.updateSpringboard("")
                            mainView.contacts = new Array
                            label1.text = qsTr("Learn about more use cases in the printed manual")
                            button1.text = qsTr("Next hint")
                            button1.enabled = true
                        }, 2000)
                    }, 2000)
                }, 2000)
            }, 2000)
        }

        function showCollectionDemo() {
            mainView.updateCollectionPage(mainView.collectionMode.News)

            timer.setTimeout(function() {
                mainView.currentIndex = 2
                button3.text = qsTr("Next hint")
                button3.enabled = true
            }, 6000)
        }

        function showRedDotDemo() {
            mainView.updateShortcutMenuState(true)

            timer.setTimeout(function() {
                mainView.updateShortcutMenuState(false)

                timer.setTimeout(function() {
                    button2.text = qsTr("Next hint")
                    button2.enabled = true
                }, 2000)
            }, 2000)
        }
    }

    Button {
        anchors.top: parent.top
        anchors.right: parent.right
        text: "x"
        flat: true
        onClicked: {
            popup.close()
        }
    }

    PageIndicator {
        id: indicator

        count: swipeView.count
        currentIndex: swipeView.currentIndex

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
}
