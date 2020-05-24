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
            mainView.currentIndex = 2
        }
    }

    Component.onCompleted: {
        mainView.switchTheme(appSettings.theme)
    }

    Settings {
        id: appSettings
        property int theme: mainView.theme.Dark
    }

    SwipeView {
        id: mainView
        anchors.fill: parent
        currentIndex: 2
        interactive: true

        property real innerSpacing : 22.0
        property real headerFontSize: 40.0
        property real largeFontSize: 20.0
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
        property var detailMode: {
            'Web' : 0,
            'Twitter' : 1,
            'MMS' : 2,
            'Mail' : 3
        }
        property

        var theme: {
            'Light': 0,
            'Dark': 1,
            'Translucent': 2
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
            'OpenCam': 20012,
            'ShowNotes': 20013,
            'ShowDialer': 20014,
            'CreatEvent': 20015
        }
        property var swipeIndex: {
            'Preferences' : 0,
            'Apps' : 1,
            'Springboard': 2,
            'Collections' : 3,
            'ConversationOrNewsOrDetails' : 4,
            'Details' : 5
        }

        property var contacts: new Array

        property string galleryApp: "com.simplemobiletools.gallery.pro"
        property string calendarApp: "com.simplemobiletools.calendar.pro"
        property string cameraApp: "com.mediatek.camera"
        property string phoneApp: "com.google.android.dialer"

        Item {
            id: settings

            Loader {
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Settings.qml", mainView)
            }
        }

        Item {
            id: appGrid

            Loader {
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/AppGrid.qml", mainView)
            }
        }

        Item {
            id: springboard

            Loader {
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Springboard.qml", mainView)
            }
        }

        function updateCollectionPage(mode) {
            console.log("MainView | New collection mode: " + mode)
            if (count === swipeIndex.Springboard + 1) {
                var item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                item.children[0].sourceComponent = Qt.createComponent("/Collections.qml", mainView)
                addItem(item)
            } else {
                item = itemAt(swipeIndex.Collections)
                while (count > swipeIndex.Collections + 2) removeItem(swipeIndex.Collections + 2)
            }
            item.children[0].item.updateCollectionPage(mode)
            currentIndex++
        }

        function updateConversationPage(mode, id, name) {
            console.log("MainView | Will update conversation page")
            if (count === swipeIndex.Collections + 1) {
                var item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                addItem(item)
            } else {
                item = itemAt(swipeIndex.ConversationOrNewsOrDetails)
                while (count > swipeIndex.ConversationOrNewsOrDetails + 2) removeItem(swipeIndex.ConversationOrNewsOrDetails + 2)
            }
            item.children[0].sourceComponent = Qt.createComponent("/Conversation.qml", mainView)
            item.children[0].item.updateConversationPage(mode, id, name)
            currentIndex++
        }

        function updateDetailPage(mode, id, author, date) {
            console.log("MainView | Will update detail page")
            switch (currentIndex) {
                case swipeIndex.Collections:
                    if (count > swipeIndex.Collections + 1) {
                        var item = itemAt(swipeIndex.ConversationOrNewsOrDetails)
                        item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                        while (count > swipeIndex.ConversationOrNewsOrDetails + 2) removeItem(swipeIndex.ConversationOrNewsOrDetails + 2)
                    } else {
                        item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                        item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                        addItem(item)
                    }
                    break
                case swipeIndex.ConversationOrNewsOrDetails:
                    if (count > swipeIndex.ConversationOrNewsOrDetails + 1) {
                        item = itemAt(swipeIndex.Details)
                        item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                        while (count > swipeIndex.ConversationOrNewsOrDetails + 2) removeItem(swipeIndex.ConversationOrNewsOrDetails + 2)
                    } else {
                        item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                        item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                        addItem(item)
                    }
                    break
                default:
                    console.log("MainView | Unexpected state for detail view request")
            }
            item.children[0].item.updateDetailPage(mode, id, author, date)
            currentIndex++
        }

        function updateNewsPage(mode, id, name, icon) {
            console.log("MainView | Will update news page")
            if (count === swipeIndex.Collections + 1) {
                var item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                addItem(item)
            } else {
                item = itemAt(swipeIndex.ConversationOrNewsOrDetails)
                while (count > swipeIndex.ConversationOrNewsOrDetails + 2) removeItem(ConversationOrNewsOrDetails.Collections + 2)
            }
            item.children[0].sourceComponent = Qt.createComponent("/Feed.qml", mainView)
            item.children[0].item.updateFeedPage(mode, id, name, icon)
            currentIndex++
        }

        function showToast(message) {
            toast.text = message
            toast.show()
        }

        function loadContacts() {
            console.log("MainView | Will load contacts")
            AN.SystemDispatcher.dispatch("volla.launcher.contactAction", {})
        }

        function switchTheme(theme) {
            Universal.theme = theme
        }

        // Todo: Improve display date and time with third party library
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
            console.log("MainView | Number of items: " + count)
        }

        Connections {
            target: AN.SystemDispatcher
            onDispatched: {
                if (type === "volla.launcher.contactResponse") {
                    console.log("MainView | onDispatched: " + type)
                    mainView.contacts = message["contacts"]
                    message["contacts"].forEach(function (aContact, index) {
                        for (const [aContactKey, aContactValue] of Object.entries(aContact)) {
                            console.log("MainView | * " + aContactKey + ": " + aContactValue)
                        }
                    })
                }
            }
        }
    }

    AN.Toast {
        id: toast
        text: qsTr("Not yet supported")
        longDuration: true
    }
}
