import QtQuick 2.12
import QtQuick.Controls 2.5

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("Tabs")

    onActiveChanged: {
        var message = active ? "active" : "not active"
        console.log("Volla app is " + message)
        if (active) {
            swipeView.currentIndex = 2
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 2
        interactive: true

        property real innerSpacing : 22.0
        property real pointSize: 20.0
        property real headerPointSize: 40.0
        property var collectionMode : {
            'People' : 0,
            'Threads' : 1,
            'News' : 2
        }
        property string galleryApp: "com.google.android.apps.photos"
        property string calendarApp: "com.google.android.calendar"
        property string cameraApp: "com.android.camera2"
        property string phoneApp: "com.google.android.dialer"

        Item {
            id: demoBrowser

            Loader {
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Browser.qml", swipeView)
            }
        }

        Item {
            id: appGrid

            Loader {
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/AppGrid.qml", swipeView)
            }
        }

        Item {
            id: springboard

            Loader {
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Springboard.qml", swipeView)
            }
        }

        Item {
            id: collectionPage

            Loader {
                id: collectionPageLoader
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Collections.qml", swipeView)
            }
        }

        Item {
            id: detailPage

            Loader {
                id: detaulPageLoader
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Details.qml", swipeView)
            }
        }

        function updateCollectionMode(mode) {
            console.log("New collection mode: " + mode)
            currentIndex = currentIndex + 1
            collectionPageLoader.item.updateCollectionMode(mode)
        }

        function updateDetailPage(imageSource, headline, placeholderText) {
            console.log("Will update detail page")
            currentIndex = currentIndex + 1
            detaulPageLoader.item.updateDetailPage(imageSource, headline, placeholderText)
        }
    }

}
