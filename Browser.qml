import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtWebView 1.1

Page {
    id: browserPage
    anchors.fill: parent

    property real menuheight: 22 * 7 + swipeView.innerSpacing * 10
    property var placeholderImage

//    WebView {
//       id: webView
//       //anchors.fill: parent
//       anchors.top: parent.top
//       anchors.left: parent.left
//       width: parent.width - swipeView.swipeView.innerSpacing
//       height: parent.height
//       url: "http://www.instagram.com"
//    }

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: 3000

        Image {
            id: placeHolderImage
            source: "/images/InstagramPlaceholder.png"
            width: parent.width
            fillMode: Image.PreserveAspectFit

            Binding {
                target: browserPage
                property: "placeholderImage"
                value: placeHolderImage
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }
    }

    MouseArea {
        id: rightMouseArea
        enabled: true
        width: 50
        height: parent.height
        anchors.right: parent.right
        anchors.top: parent.top
        preventStealing: true

        property bool wasSuccessful

        onEntered: {
            console.log("Open right menu")

//            wasSuccessful = webView.grabToImage(function(result) {
//                console.log("WebView grabbed: " + result.url)
//                placeHolder.source = result.url
//                webView.visible = false
//            })

//            console.log("Was successful " + wasSuccessful)

            rightMenu.open()
        }
    }

    Drawer {
        id: rightMenu
        z: 2
        edge: Qt.RightEdge
        width: parent.width * 0.5
        height: parent.height

        onOpenedChanged: {
            if (rightMenu.opened) {
                browserPage.placeholderImage.opacity = 0.5
            } else {
                browserPage.placeholderImage.opacity = 1.0
            }
        }

        background: Rectangle {
            anchors.fill: parent
            color: Universal.accent
        }

        MouseArea {
            id: shortcutMenu
            width: parent.width
            height: parent.height
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            enabled: true

            property var selectedMenuItem: shortcutColumn

            onSelectedMenuItemChanged: {
                peopleLabel.font.bold = selectedMenuItem === peopleLabel
                peopleLabel.font.pointSize = selectedMenuItem === peopleLabel ?swipeView.largeFontSize * 1.2: swipeView.largeFontSize
                threadLabel.font.bold = selectedMenuItem === threadLabel
                threadLabel.font.pointSize = selectedMenuItem === threadLabel ?swipeView.largeFontSize * 1.2: swipeView.largeFontSize
                newsLabel.font.bold = selectedMenuItem === newsLabel
                newsLabel.font.pointSize = selectedMenuItem === newsLabel ?swipeView.largeFontSize * 1.2: swipeView.largeFontSize
                galleryLabel.font.bold = selectedMenuItem === galleryLabel
                galleryLabel.font.pointSize = selectedMenuItem === galleryLabel ?swipeView.largeFontSize * 1.2: swipeView.largeFontSize
                agendaLabel.font.bold = selectedMenuItem === agendaLabel
                agendaLabel.font.pointSize = selectedMenuItem === agendaLabel ?swipeView.largeFontSize * 1.2: swipeView.largeFontSize
                cameraLabel.font.bold = selectedMenuItem === cameraLabel
                cameraLabel.font.pointSize = selectedMenuItem === cameraLabel ?swipeView.largeFontSize * 1.2: swipeView.largeFontSize
                dialerLabel.font.bold = selectedMenuItem === dialerLabel
                dialerLabel.font.pointSize = selectedMenuItem === dialerLabel ?swipeView.largeFontSize * 1.2: swipeView.largeFontSize
            }

            onEntered: {
                console.log("entered")
            }

            onExited: {
                console.log("exited")
                shortcutMenu.executeSelection()
                selectedMenuItem = shortcutColumn
                rightMenu.close()
            }

            onCanceled: {
                console.log("cancelled")
                shortcutMenu.executeSelection()
                selectedMenuItem = shortcutColumn
                rightMenu.close()
            }

            onPositionChanged: {
                var plPoint = mapFromItem(peopleLabel, 0, 0)
                var tlPoint = mapFromItem(threadLabel, 0, 0)
                var nlPoint = mapFromItem(newsLabel, 0, 0)
                var glPoint = mapFromItem(galleryLabel, 0, 0)
                var alPoint = mapFromItem(agendaLabel, 0, 0)
                var clPoint = mapFromItem(cameraLabel, 0, 0)
                var dlPoint = mapFromItem(dialerLabel, 0, 0)

                if (mouseY > plPoint.y && mouseY < plPoint.y + peopleLabel.height) {
                    selectedMenuItem = peopleLabel
                } else if (mouseY > tlPoint.y && mouseY < tlPoint.y + threadLabel.height) {
                    selectedMenuItem = threadLabel
                } else if (mouseY > nlPoint.y && mouseY < nlPoint.y + newsLabel.height) {
                    selectedMenuItem = newsLabel
                } else if (mouseY > glPoint.y && mouseY < glPoint.y + galleryLabel.height) {
                    selectedMenuItem = galleryLabel
                } else if (mouseY > alPoint.y && mouseY < alPoint.y + agendaLabel.height) {
                    selectedMenuItem = agendaLabel
                } else if (mouseY > clPoint.y && mouseY < clPoint.y + cameraLabel.height) {
                    selectedMenuItem = cameraLabel
                } else if (mouseY > dlPoint.y && mouseY < dlPoint.y + dialerLabel.height) {
                    selectedMenuItem = dialerLabel
                } else {
                    selectedMenuItem = shortcutColumn
                }
            }

            function executeSelection() {
                var collectionPage = Qt.createComponent("/Collections.qml")

                if (selectedMenuItem == peopleLabel) {
                    console.log("Show people")
                    swipeView.updateCollectionMode(swipeView.collectionMode.People)
                } else if (selectedMenuItem == threadLabel) {
                    console.log("Show threads")
                    swipeView.updateCollectionMode(swipeView.collectionMode.Threads)
                } else if (selectedMenuItem == newsLabel) {
                    console.log("Show news")
                    swipeView.updateCollectionMode(swipeView.collectionMode.News)
                } else if (selectedMenuItem == galleryLabel) {
                    console.log("Show gallery")
                    backEnd.runApp(swipeView.galleryApp)
                } else if (selectedMenuItem == agendaLabel) {
                    console.log("Show agenda")
                    backEnd.runApp(swipeView.calendarApp)
                } else if (selectedMenuItem == cameraLabel) {
                    console.log("Show camera")
                    backEnd.runApp(swipeView.cameraApp)
                } else if (selectedMenuItem == dialerLabel) {
                    console.log("Show dialer")
                    backEnd.runApp(swipeView.phoneApp)
                }
            }

            Column {
                id: shortcutColumn
                visible: true // shortcutBackground.visible
                width: parent.width
                height: menuheight
                anchors.bottom: parent.bottom

                property int duration: 200

                Label {
                    id: dialerLabel
                    text: qsTr("Show Dialer")
                    font.pointSize:swipeView.largeFontSize
                    anchors.left: parent.left
                    topPadding: swipeView.innerSpacing * 2
                    leftPadding: swipeView.innerSpacing
                    bottomPadding: swipeView.innerSpacing
                }
                Label {
                    id: cameraLabel
                    text: qsTr("Open Camera")
                    font.pointSize:swipeView.largeFontSize
                    anchors.left: parent.left
                    leftPadding: swipeView.innerSpacing
                    bottomPadding: swipeView.innerSpacing
                }
                Label {
                    id: agendaLabel
                    text: qsTr("Agenda")
                    font.pointSize:swipeView.largeFontSize
                    anchors.left: parent.left
                    leftPadding: swipeView.innerSpacing
                    bottomPadding: swipeView.innerSpacing
                }
                Label {
                    id: galleryLabel
                    text: qsTr("Gallery")
                    font.pointSize:swipeView.largeFontSize
                    anchors.left: parent.left
                    leftPadding: swipeView.innerSpacing
                    bottomPadding: swipeView.innerSpacing
                }
                Label {
                    id: newsLabel
                    text: qsTr("Recent News")
                    font.pointSize:swipeView.largeFontSize
                    anchors.left: parent.left
                    leftPadding: swipeView.innerSpacing
                    bottomPadding: swipeView.innerSpacing
                }
                Label {
                    id: threadLabel
                    text: qsTr("Recent Threads")
                    font.pointSize:swipeView.largeFontSize
                    anchors.left: parent.left
                    leftPadding: swipeView.innerSpacing
                    bottomPadding: swipeView.innerSpacing
                }
                Label {
                    id: peopleLabel
                    text: qsTr("Revent People")
                    font.pointSize:swipeView.largeFontSize
                    anchors.left: parent.left
                    leftPadding: swipeView.innerSpacing
                    bottomPadding: swipeView.innerSpacing * 2
                }
            }
        }
    }


}
