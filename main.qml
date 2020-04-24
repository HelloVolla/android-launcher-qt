import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import AndroidNative 1.0 as AN

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("Volla")

    onActiveChanged: {
        var message = active ? "active" : "not active"
        console.log("MainView | Volla app is " + message)
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
        property real headerFontSize: 40.0
        property real largeFontSize: 22.0
        property real mediumFontSize: 18.0
        property real smallFontSize: 16.0

        property var collectionMode : {
            'People' : 0,
            'Threads' : 1,
            'News' : 2
        }
        property var conversationMode: {
            'Person' : 0,
            'Thread' : 1
        }
        property var feedMode: {
            'RSS' : 0,
            'Twitter': 1
        }
        property var actionType: {
            'SuggestContact': 0,
            'MakeCall': 20000,
            'SendEmail': 20001,
            'SendSMS': 20002,
            'OpenURL': 20003,
            'SearchWeb': 20004,
            'CreateNote': 20005,
            'ShowGroup': 20006,
            'ShowDetails': 20007,
            'ShowGallery': 20008,
            'ShowConacts': 20009,
            'ShowThreads': 20010,
            'ShowNews': 20011,
            'OpenCam': 20012
        }
        property var contacts: new Array

        property var newsPage

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
            id: conversationAndNewsPage

            Loader {
                id: conversationAndNewsPageLoader
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Conversation.qml", swipeView)
            }
        }

        Item {
            id: detailPage

            Loader {
                id: detailPageLoader
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Details.qml", swipeView)
            }
        }

        function updateCollectionMode(mode) {
            console.log("MainView | New collection mode: " + mode)
            currentIndex = currentIndex + 1
            collectionPageLoader.item.updateCollectionMode(mode)
        }

        function updateConversationPage(mode, id, name) {
            console.log("MainView | Will update conversation page")
            conversationAndNewsPageLoader.sourceComponent = Qt.createComponent("/Conversation.qml", swipeView)
            conversationAndNewsPageLoader.item.updateConversationPage(mode, id, name)
            currentIndex = currentIndex + 1
        }

        function updateDetailPage(imageSource, headline, placeholderText) {
            console.log("MainView | Will update detail page")
            currentIndex = currentIndex + 1
            detailPageLoader.item.updateDetailPage(imageSource, headline, placeholderText)
        }

        function updateNewsPage(mode, id, name, icon) {
            console.log("MainView | Will update news page")
            conversationAndNewsPageLoader.sourceComponent = Qt.createComponent("/Feed.qml", swipeView)
            conversationAndNewsPageLoader.item.updateFeedPage(mode, id, name, icon)
            currentIndex = currentIndex + 1
        }

        function loadContacts() {
            console.log("MainView | Will load contacts")
            AN.SystemDispatcher.dispatch("volla.launcher.contactAction", {})
        }

        // Todo: Improve display date and time
        function parseTime(timeInMillis) {
            var now = new Date()
            var date = new Date(timeInMillis)
            var today = new Date()
            today.setHours(0)
            today.setMinutes(0)
            today.setMilliseconds(0)
            var yesterday = new Date()
            yesterday.setHours(0)
            yesterday.setMinutes(0)
            yesterday.setMilliseconds(0)
            yesterday = new Date(yesterday.valueOf() - 84000 * 1000)
            var timeDelta = (now.valueOf() - timeInMillis) / 1000 / 60
            if (timeDelta < 1) {
                return qsTr("Just now")
            } else if (timeDelta < 60) {
                return Math.floor(timeDelta) + " " + qsTr("minutes ago")
            } else if (date.valueOf() > today.valueOf()) {
                if (date.getMinutes() < 10) {
                    return qsTr("Today") + " " + date.getHours() + ":0" + date.getMinutes()
                } else {
                    return qsTr("Today") + " " + date.getHours() + ":" + date.getMinutes()
                }
            } else if (date.valueOf() > yesterday.valueOf()) {
                if (date.getMinutes() < 10) {
                    return qsTr("Yesterday") + " " + date.getHours() + ":0" + date.getMinutes()
                } else {
                    return qsTr("Yesterday") + " " + date.getHours() + ":" + date.getMinutes()
                }
            } else if (date.getMinutes() < 10) {
                return date.toLocaleDateString() + " " + date.getHours() + ":0" + date.getMinutes()
            } else {
                return date.toLocaleDateString() + " " + date.getHours() + ":" + date.getMinutes()
            }
        }

        Component.onCompleted: {
            loadContacts()
        }

        Connections {
            target: AN.SystemDispatcher
            onDispatched: {
                if (type === "volla.launcher.contactResponse") {
                    console.log("MainView | onDispatched: " + type)
                    swipeView.contacts = message["contacts"]
                    message["contacts"].forEach(function (aContact, index) {
                        for (const [aContactKey, aContactValue] of Object.entries(aContact)) {
                            console.log("MainView | * " + aContactKey + ": " + aContactValue)
                        }
                    })
                }
            }
        }
    }

}
