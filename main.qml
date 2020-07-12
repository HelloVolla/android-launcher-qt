import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN
import Qt.labs.settings 1.0
import QtQml 2.12
import FileIO 1.0

ApplicationWindow {
    visible: true
    width: 640
    height: 1200
    title: qsTr("Volla")

    // Todo: Introduce setting
    // visibility: ApplicationWindow.FullScreen

    Connections {
       target: Qt.application
       onStateChanged: {
          if (Qt.application.state === Qt.ApplicationActive) {
              // Application go in active state
              console.log("Application became active")
              mainView.currentIndex = mainView.swipeIndex.Springboard
              mainView.loadWallPaper()
              mainView.updateAppGrid()
              mainView.loadContacts()
          } else {
              // Application go in suspend state
              console.log("Application became inactive")
          }
       }
    }

    onActiveChanged: {
        if (active) {
            AN.SystemDispatcher.dispatch("volla.launcher.layoutAction", { })
        }
    }

    Component.onCompleted: {
        console.log("MainView | Current locale: " + Qt.locale().name)
    }

    SwipeView {
        id: mainView
        anchors.fill: parent
        currentIndex: 2
        interactive: true

        background: Item {
            id: background
            anchors.fill: parent
            Image {
                id: backgroundImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: mainView.wallpaper
            }
            FastBlur {
                anchors.fill: backgroundImage
                source: backgroundImage
                radius: 60
            }
            Rectangle {
                anchors.fill: parent
                color: Universal.background
                opacity: mainView.backgroundOpacity

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
         }

        property real innerSpacing : 22.0
        property real headerFontSize: 36.0
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
        property var theme: {
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
        property double lastContactsCheck: 0
        property var wallpaper: ""
        property var wallpaperId: ""
        property var backgroundOpacity: 1.0
        property var fontColor: Universal.foreground

        property string galleryApp: "com.simplemobiletools.gallery.pro"
        property string calendarApp: "com.simplemobiletools.calendar.pro"
        property string cameraApp: "com.mediatek.camera"
        property string phoneApp: "com.android.dialer"
        property string messageApp: "com.android.mms" // "org.smssecure.smssecure"

        property var defaultFeeds: [{"id" : "https://www.nzz.ch/recent.rss", "name" : "NZZ", "activated" : true, "icon": "https://assets.static-nzz.ch/nzz/app/static/favicon/favicon-128.png?v=3"},
            {"id" : "https://www.chip.de/rss/rss_topnews.xml", "name": "Chip Online", "activated" : true, "icon": "https://www.chip.de/fec/assets/favicon/apple-touch-icon.png?v=01"},
            {"id" : "https://www.theguardian.com/world/rss", "name": "The Guardian", "activated" : true, "icon":  "https://assets.guim.co.uk/images/favicons/6a2aa0ea5b4b6183e92d0eac49e2f58b/57x57.png"}]
        property var defaultActions: [{"id" : actionType.ShowDialer, "name" : "Show Dialer", "activated" : true},
            {"id" : actionType.OpenCam, "name": "Camera", "activated" : true},
            {"id" : actionType.ShowCalendar, "name": "Agenda", "activated" : true},
            {"id" : actionType.ShowGallery, "name": "Gallery", "activated" : true},
            {"id" : actionType.ShowNotes, "name": "Notes", "activated" : false},
            {"id" : actionType.CreateEvent, "name": "Create Event", "activated" : false},
            {"id" : actionType.ShowContacts, "name": "Recent People", "activated" : true},
            {"id" : actionType.ShowThreads, "name": "Recent Threads", "activated" : true},
            {"id" : actionType.ShowNews, "name": "Recent News", "activated" : true}]

        onCurrentIndexChanged: {
            if (currentIndex === swipeIndex.Apps) {
                appGrid.children[0].item.updateNotifications()
            }
        }

        Item {
            id: settingsPage

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
                    console.log("MainView | Current page is a collection")
                    if (count > swipeIndex.Collections + 1) {
                        var item = itemAt(swipeIndex.ConversationOrNewsOrDetails)
                        if (item.children[0].item.objectName !== "detailPage") {
                            console.log("MainView | Create detail page")
                            item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                            while (count > swipeIndex.ConversationOrNewsOrDetails + 2) removeItem(swipeIndex.ConversationOrNewsOrDetails + 2)
                        } else {
                            console.log("MainView | Re-use existing detail page")
                        }
                     } else {
                        item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                        item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                        addItem(item)
                    }
                    break
                case swipeIndex.ConversationOrNewsOrDetails:
                    console.log("MainView | Current page is a news or detail view")
                    if (count > swipeIndex.ConversationOrNewsOrDetails + 1) {
                        item = itemAt(swipeIndex.Details)
                        if (item.children[0].item.objectName !== "detailPage") {
                            console.log("MainView | Create detail page")
                            item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                            while (count > swipeIndex.ConversationOrNewsOrDetails + 2) removeItem(swipeIndex.ConversationOrNewsOrDetails + 2)
                        } else {
                            console.log("MainView | Re-use existing detail page")
                        }
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

        function updateAppGrid() {
            AN.SystemDispatcher.dispatch("volla.launcher.appCountAction", {})
        }

        function showToast(message) {
            toast.text = message
            toast.show()
        }

        function loadContacts() {
            console.log("MainView | Will load contacts")
            AN.SystemDispatcher.dispatch("volla.launcher.checkContactAction", {"timestamp": mainView.lastContactsCheck})
        }

        function loadWallPaper() {
            AN.SystemDispatcher.dispatch("volla.launcher.wallpaperAction", {"wallpaperId": mainView.wallpaperId})
        }

        function switchTheme(theme) {
            settings.sync()
            console.log("MainView | Swith theme to " + theme + ", " + settings.theme)
            switch (theme) {
            case mainView.theme.Dark:
                Universal.theme = Universal.Dark
                mainView.backgroundOpacity = 1.0
                break
            case mainView.theme.Light:
                Universal.theme = Universal.Light
                mainView.backgroundOpacity = 1.0
                break
            case mainView.theme.Translucent:
                Universal.theme = Universal.Dark
                mainView.backgroundOpacity = 0.3
                break
            default:
                console.log("Not supported theme: " + theme)
                break
            }
            mainView.fontColor = Universal.foreground
            AN.SystemDispatcher.dispatch("volla.launcher.colorAction", { "value": theme})
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

        function getFeeds() {
            var channels = feeds.read()
            console.log("MainView | Retrieved feeds: " + channels)
            return channels.length > 0 ? JSON.parse(channels) : mainView.defaultFeeds
        }

        function updateFeed(channelId, isActive) {
            // Todo: implement
            var channels = getFeeds()
            for (var i = 0; i < channels.length; i++) {
                var channel = channels[i]
                if (channel["id"] === channelId) {
                    channel["activated"] = isActive
                    channels[i] = channel
                    console.log("MainView | Did store feeds: " + feeds.write(JSON.stringify(channels)))
                    break
                }
            }
        }

        Connections {
            target: AN.SystemDispatcher
            onDispatched: {
                if (type === "volla.launcher.contactResponse") {
                    console.log("MainView | onDispatched: " + type)
                    mainView.contacts = message["contacts"]
                    mainView.lastContactsCheck = new Date().getTime()
//                    message["contacts"].forEach(function (aContact, index) {
//                        for (const [aContactKey, aContactValue] of Object.entries(aContact)) {
//                            console.log("MainView | * " + aContactKey + ": " + aContactValue)
//                        }
//                    });
                } else if (type === "volla.launcher.checkContactResponse") {
                    console.log("MainView | onDispatched: " + type)
                    if (message["needsSync"]) {
                        console.log("MainView | Need to sync contacts")
                        AN.SystemDispatcher.dispatch("volla.launcher.contactAction", {})
                    }
                } else if (type === "volla.launcher.wallpaperResponse") {
                    console.log("MainView | onDispatched: " + type)
                    if (message["wallpaper"] !== undefined) {
                        mainView.wallpaper = "data:image/png;base64," + message["wallpaper"]
                    }
                    mainView.wallpaperId = message["wallpaperId"]
                }
            }
        }
    }

    Settings {
        id: settings
        property int theme: mainView.theme.Dark
        
        Component.onCompleted: {
            console.log("Current themes: " + Universal.theme + ", " + settings.theme)
            if (Universal.theme !== settings.theme) {
                mainView.switchTheme(settings.theme)
            }
        }
    }

    AN.Toast {
        id: toast
        text: qsTr("Not yet supported")
        longDuration: true
    }

    FileIO {
        id: feeds
        source: "feeds.json"
        onError: {
            console.log(msg)
        }
    }
}
