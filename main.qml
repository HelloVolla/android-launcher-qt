import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.2
import QtQuick.Controls.Universal 2.12
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN
import Qt.labs.settings 1.0
import QtQml 2.12
import FileIO 1.0

ApplicationWindow {
    id: appWindow
    visible: true
    title: qsTr("Volla")

    property ApplicationWindow mainWindow : appWindow

    property bool isActive: false

    onClosing: close.accepted = false

    Connections {
       target: Qt.application
       // @disable-check M16
       onStateChanged: {
          if (Qt.application.state === Qt.ApplicationActive) {              
              if (isActive) return
              isActive = true
              // Application go in active state
              console.log("MainView | Application became active")
              if (Qt.fontFamilies().indexOf("Noto Sans") > -1) {
                  console.debug("APP: Use smaller font size")
                  mainView.headerFontSize = 34.0
                  mainView.largeFontSize = 18.0
                  mainView.mediumFontSize = 16.0
                  mainView.smallFontSize = 14.0
              }
              settings.sync()
              if (!appGridLoader.active) appGridLoader.active = true
              if (!springboardLoader.active) springboardLoader.active = true
              if (!settingsPageLoader.active) settingsPageLoader.active = true
              if (mainView.keepLastIndex) {
                  if (mainView.currentIndex === mainView.swipeIndex.ConversationOrNewsOrDetails) {
                      console.log("MainView | Switch to conversation page")
                      mainView.currentIndex = mainView.swipeIndex.ConversationOrNewsOrDetails
                  }
                  mainView.keepLastIndex = false
              } else {
                  if (settings.showAppsAtStartup && mainView.currentIndex === mainView.swipeIndex.Apps)
                      appGrid.children[0].item.updateNotifications()
                  mainView.currentIndex = settings.showAppsAtStartup ? mainView.swipeIndex.Apps : mainView.swipeIndex.Springboard
              }
              // Check runnung apps
              if (mainView.isTablet) AN.SystemDispatcher.dispatch("volla.launcher.runningAppsAction", {})
              // Start onboarding for the first start of the app
              console.log("MainView | First start: " + settings.firstStart)
              // Check new pinned shortcut
              AN.SystemDispatcher.dispatch("volla.launcher.checkNewShortcut", {})
              // Update app grid
              AN.SystemDispatcher.dispatch("volla.launcher.appCountAction", {})
              // Load wallpaper
              AN.SystemDispatcher.dispatch("volla.launcher.wallpaperAction", {"wallpaperId": mainView.wallpaperId})
              // Load contacts
              AN.SystemDispatcher.dispatch("volla.launcher.checkContactAction", {"timestamp": settings.lastContactsCheck})
          } else if (Qt.application.state === Qt.ApplicationInactive) {
              // Application go in suspend state
              console.log("MainView | Application became inactive")
              isActive = false
              appGridLoader.active = false
              springboardLoader.active = false
              settingsPageLoader.active = false
          }
       }
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
                id: fastBlur
                anchors.fill: backgroundImage
                source: backgroundImage
                radius: settings.blurEffect
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

        property real outerSpacing: Screen.desktopAvailableWidth > 520 ? 100 : 0
        property real innerSpacing : Screen.desktopAvailableWidth > 520 ? 22 : 22 // 22.0
        property real componentSpacing: Screen.desktopAvailableWidth > 520 ? 32 : 22
        property real headerFontSize: 36.0
        property real largeFontSize: 20.0
        property real mediumFontSize: 18.0
        property real smallFontSize: 16.0

        property var collectionMode : {
            'People' : 0,
            'Threads' : 1,
            'News' : 2,
            'Notes' : 3
        }
        property var conversationMode: {
            'Person' : 0,
            'Thread' : 1
        }
        property var feedMode: {
            'RSS' : 0,
            'Atom' : 1,
            'Twitter': 2
        }
        property var detailMode: {
            'Web' : 0,
            'Twitter' : 1,
            'MMS' : 2,
            'Mail' : 3,
            'Note' : 4
        }
        property var searchMode: {
            'Duck' : 0,
            'StartPage' : 1,
            'MetaGer' : 2,
            'Custom' : 3
        }
        property var theme: {
            'Light': 0,
            'Dark': 1,
            'LightTranslucent': 2,
            'DarkTranslucent': 3
        }
        property var actionType: {
            'SuggestContact': 0,
            'SuggestPluginEntity' : 1,
            'MakeCall': 20000,
            'SendEmail': 20001,
            'SendSMS': 20002,
            'OpenURL': 20003,
            'SearchWeb': 20004,
            'CreateNote': 20005,
            'ShowGroup': 20006,
            'ShowDetails': 20007,
            'ShowGallery': 20008,
            'ShowContacts': 20009,
            'ShowCalendar' : 20010,
            'ShowThreads': 20011,
            'ShowNews': 20012,
            'OpenCam': 20013,
            'ShowNotes': 20014,
            'ShowDialer': 20015,
            'CreateEvent': 20016,
            'AddFeed': 20017,
            'MakeCallToMobile': 20018,
            'MakeCallToWork': 20019,
            'MakeCallToHome': 20020,
            'MakeCallToOther': 20021,
            'SendEmailToHome': 20022,
            'SendEmailToWork': 20023,
            'SendEmailToOther': 20024,
            'OpenContact' : 20025,
            'OpenApp' : 20026,
            'SendSignal' : 20027,
            'OpenSignalContact' : 20028,
            'ExecutePlugin': 20029,
            'LiveContentPlugin': 20030,
            'Redial': 20031,
            'CreateContact' : 20032,
            'CreateSpeedDial' : 20033
        }
        property var actionName: {"SendSMS": qsTr("Send message"), "SendEmail": qsTr("Send email"),
            "SendEmailToHome": qsTr("Send home email"), "SendEmailToWork": qsTr("Send work email"),
            "SendEmailToOther": qsTr("Send other email"), "MakeCall": qsTr("Call"), "CreateSpeedDial" : qsTr("Create speed dial"),
            "MakeCallToMobile": qsTr("Call on cell phone"), "MakeCallToHome": qsTr("Call at home"),
            "MakeCallToWork": qsTr("Call at work"), "MakeCallToOther": qsTr("Call other phone"),
            "CreateNote": qsTr("Create note"), "SearchWeb": qsTr("Search web"), "CreateContact" : qsTr("Create new contact"),
            "OpenURL": qsTr("Open in browser"), "AddFeed": qsTr("Add feed to collection"),
            "OpenContact" : qsTr("Open Contact"), "ShowNotes": qsTr("Show Notes"), "SendSignal" : qsTr("Send Signal message"),
            "CreateEvent" : qsTr("Add to Calender"), "OpenSignalContact": qsTr("Show in Signal"), "Redial" : qsTr("Redial")
        }
        property var swipeIndex: {
            'Preferences' : 0,
            'Apps' : 1,
            'Springboard' : 2,
            'Collections' : 3,
            'ConversationOrNewsOrDetails' : 4,
            'Details' : 5
        }
        property var settingsAction: {
            'CREATE': 0,
            'UPDATE': 1,
            'REMOVE': 2
        }
        property var notifications: { "MissingText": qsTr("Missing message text"),
                                      "MessageSent": qsTr("Message sent"),
                                      "GenericFailure": qsTr("Generic failure"),
                                      "NoService": qsTr("No service"),
                                      "NullPdu": qsTr("Null PDU"),
                                      "RadioOff": qsTr("Radio off"),
                                      "MessageDelivered": qsTr("Message delivered"),
                                      "MessageNotDelivered": qsTr("Message not delivered")}
        property var contacts: new Array
        property var notes: new Array
        property var loadingContacts: new Array
        property bool isLoadingContacts: false
        property var wallpaper: ""
        property var wallpaperId: ""
        property var backgroundOpacity: 1.0
        property var backgroundColor: Universal.background
        property var accentColor: Universal.accent
        property var accentTextColor: getContrastColor(accentColor)
        property var fontColor: Universal.foreground
        
        function getContrastColor(hexColor) {
            // If no custom accent color is set (default/system color), always use white text
            if (settings.customAccentColor === "" || settings.customAccentColor.length === 0) {
                return "white";
            }
            
            // For custom hex colors, calculate proper contrast
            if (hexColor.startsWith("#")) {
                var r = parseInt(hexColor.substr(1, 2), 16);
                var g = parseInt(hexColor.substr(3, 2), 16);
                var b = parseInt(hexColor.substr(5, 2), 16);
                
                // Calculate luminance using WCAG formula
                var luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
                
                // Return black for light colors, white for dark colors
                return luminance > 0.5 ? "black" : "white";
            }
            
            // Fallback for any other case
            return "white";
        }

        property var vibrationDuration: 50
        property bool useVibration: settings.useHapticMenus
        property bool useColoredIcons: settings.useColoredIcons
        property bool isTablet: Screen.desktopAvailableWidth > 520
        property int maxTitleLength: 120

        property string searchEngineName
        property string searchEngineUrl
        property string galleryApp: "org.fossify.gallery"
        property string calendarApp: "org.fossify.calendar"
        property string cameraApp: "com.mediatek.camera"
        property string phoneApp: "com.android.dialer"
        property string notesApp: "org.fossify.notes"
        property var messageApp: ["com.android.mms", "org.fossify.messages", "com.android.messaging"];
        property var iconMap: {
            "com.simplemobiletools.dialer": "/icons/dial-phone@4x.png",
            "com.simplemobiletools.smsmessenger": "/icons/message@4x.png",
            "com.simplemobiletools.gallery.pro": "/icons/photo-gallery@4x.png",
            "com.simplemobiletools.contacts.pro": "/icons/people-contacts-agenda@4x.png",
            "com.simplemobiletools.clock": "/icons/clock@4x.png",
            "com.simplemobiletools.calendar.pro": "/icons/calendar@4x.png",
            "com.simplemobiletools.filemanager.pro": "/icons/folder@4x.png",
            "com.simplemobiletools.notes.pro": "/icons/notes@4x.png",
            "com.simplemobiletools.calculator": "/icons/calculator@4x_104x104px.png",
            "org.fossify.phone": "/icons/dial-phone@4x.png",
            "org.fossify.smsmessenger": "/icons/message@4x.png",
            "org.fossify.gallery": "/icons/photo-gallery@4x.png",
            "org.fossify.contacts": "/icons/people-contacts-agenda@4x.png",
            "org.fossify.clock": "/icons/clock@4x.png",
            "org.fossify.calendar": "/icons/calendar@4x.png",
            "org.fossify.filemanager": "/icons/folder@4x.png",
            "org.fossify.notes": "/icons/notes@4x.png",
            "org.fossify.calculator": "/icons/calculator@4x_104x104px.png",
            "org.fossify.musicplayer": "/icons/music@4x.png",
            "com.volla.messages": "/icons/volla-messages@4x.png",
            "com.contactoffice.mailfence": "/icons/email@4x.png",
            "com.emclient.mailclient": "/icons/email@4x.png",
            "net.thunderbird.android": "/icons/email@4x.png",
            "be.engie.smart": "/icons/engie@4x.png",
            "be.bmid.itsme": "/icons/itsme@4x.png",
            "com.facebook.lite": "/icons/facebook-lite@4x.png",
            "nl.apcreation.woolsocks": "/icons/woolsocks@4x.png",
            "com.zhiliaoapp.musically": "/icons/tiktok@4x.png",
            "com.proximus.proximusplus": "/icons/my-proximus@4x.png",
            "mobi.inthepocket.bcmc.bancontact": "/icons/payconiq@4x.png",
            "com.symantec.mobilesecurity": "/icons/norton-360@4x.png",
            "be.nexuzhealth.mobile.mynexuz": "/icons/my-nexuzhealth@4x.png",
            "com.bookmark.money": "/icons/money-lover@4x.png",
            "be.bpost.mybpost": "/icons/bpost@4x.png",
            "be.ixor.doccle.android": "/icons/doccle@4x.png",
            "com.themobilecompany.delijn": "/icons/de-lijn@4x.png",
            "com.x8bit.bitwarden": "/icons/bitwarden@4x.png",
            "com.beeper.android": "/icons/beeper@4x.png",
            "be.argenta.bankieren": "/icons/argenta@4x.png",
            "com.android.dialer": "/icons/dial-phone@4x.png",
            "com.android.mms" : "/icons/message@4x.png",
            "com.android.messaging": "/icons/message@4x.png",
            "com.google.android.apps.messaging" : "/icons/message@4x.png",
            "net.osmand.plus": "/icons/route-directions-map@4x.png",
            "com.mediatek.camera": "/icons/camera@4x.png",
            "com.android.camera2": "/icons/camera@4x.png",
            "com.android.gallery3d": "/icons/photo-gallery@4x.png",
            "com.android.deskclock": "/icons/clock@4x.png",
            "com.android.settings": "/icons/settings@4x.png",
            "com.android.documentsui": "/icons/folder@4x.png",
            "org.telegram.messenger": "/icons/telegram@4x.png",
            "com.android.email": "/icons/email@4x.png",
            "com.fsck.k9": "/icons/email@4x.png",
            "com.google.android.gm": "/icons/email@4x.png",
            "com.Slack": "/icons/slack@4x.png",
            "org.mozilla.fennec_fdroid": "/icons/browser@4x.png",
            "com.maxfour.music": "/icons/music@4x.png",
            "com.instagram.android": "/icons/instagram@4x.png",
            "com.github.yeriomin.yalpstore": "/icons/yalp-store@4x.png",
            "com.aurora.store": "/icons/aurora-store-line@4x.png",
            "com.amazon.mShop.android.shopping": "/icons/amazon@4x.png",
            "de.hafas.android.db": "/icons/db-navigator@4x.png",
            "com.dropbox.android": "/icons/dropbox@4x.png",
            "org.fdroid.fdroid": "/icons/f-droid@4x.png",
            "com.facebook.katana": "/icons/facebook@4x.png",
            "de.gmx.mobile.android.mail": "/icons/gmx@4x.png",
            "hideme.android.vpn.noPlayStore": "/icons/hide-me@4x.png",
            "com.linkedin.android": "/icons/linkedin@4x.png",
            "com.nextcloud.client": "/icons/nextcloud@4x.png",
            "com.paypal.android.p2pmobile": "/icons/paypal@4x.png",
            "com.skype.raider": "/icons/skype@4x.png",
            "com.spotify.music": "/icons/spotify@4x.png",
            "de.tutao.tutanota": "/icons/tutanota@4x.png",
            "com.volla.launcher": "/icons/volla-settings@4x.png",
            "de.web.mobile.android.mail": "/icons/web-de@4x.png",
            "com.wetter.androidclient": "/icons/wetter-com@4x.png",
            "com.whatsapp": "/icons/whats-app@4x.png",
            "com.android.fmradio": "/icons/radio@4x_104x104px.png",
            "at.bitfire.davdroid": "/icons/sync@4x_104x104px.png",
            "org.thoughtcrime.securesms": "/icons/signal@4x_104x104px.png",
            "de.baumann.weather": "/icons/weather@4x_104x104px.png",
            "com.android.calculator2": "/icons/calculator@4x_104x104px.png",
            "eu.siacs.conversations": "/icons/xmpp@4x_104x104px.png",
            "one.socializer.android": "/icons/socializer@4x.png",
            "im.status.ethereum": "/icons/status.im@4x.png",
            "org.liberty.android.freeotpplus": "/icons/freeOTP@4x.png",
            "com.kickstarter.kickstarter": "/icons/kickstarter@4x.png",
            "com.ebay.kleinanzeigen": "/icons/ebay@4x.png",
            "com.secuso.privacyFriendlyCodeScanner": "/icons/qr-scanner@4x.png",
            "com.twitter.android": "/icons/twitter@4x.png",
            "com.commerzbank.photoTAN": "/icons/photoTAN@4x.png",
            "com.volla.messages": "/icons/volla-messages@4x.png"
        }
        property var labelMap: {
            "com.simplemobiletools.filemanager.pro": qsTr("Files"),
            "com.simplemobiletools.smsmessenger": qsTr("Messages"),
            "org.fossify.filemanager": qsTr("Files"),
            "org.fossify.smsmessenger": qsTr("Messages"),
            "org.fossify.musicplayer": qsTr("Music"),
            "mobi.inthepocket.bcmc.bancontact": qsTr("Bancontact"),
            "be.sncbnmbs.b2cmobapp": qsTr("De Trein"),
            "be.nexuzhealth.mobile.mynexuz": qsTr("Mynexuzhealth"),
            "com.codesynd.cashfree": qsTr("Bonsai"),
            "be.introlution.myonlinecalendar": qsTr("MijnOnlineAgenda"),
            "com.facebook.lite": qsTr("Facebook"),
            "org.mozilla.fennec_fdroid": qsTr("Browser"),
            "com.google.android.gm" : qsTr("Mail"),
            "eu.faircode.email" : qsTr("Mail"),
            "com.emclient.mailclient" : qsTr("Mail"),
            "net.thunderbird.android" : qsTr("Mail"),
            "com.fsck.k9": qsTr("Mail"),
            "at.bitfire.davdroid": qsTr("Sync"),
            "hideme.android.vpn.noPlayStore": qsTr("VPN"),
            "com.aurora.store": qsTr("Store"),
            "com.aurora.adroid": qsTr("A-Droid"),
            "net.osmand.plus": qsTr("Maps"),
            "com.volla.launcher": qsTr("Settings"),
            "com.android.fmradio" : qsTr("Radio"),
            "de.baumann.weather": qsTr("Weather")
        }

        property string cacheName: "VollaCacheDB"
        property string cacheDescription: "Messages cache"
        property real cacheVersion: 1.0
        property int cacheSize: 1000

        property var defaultFeeds: [{"id" : "https://www.nzz.ch/recent.rss", "name" : "NZZ", "activated" : true, "icon": "https://assets.static-nzz.ch/nzz/app/static/favicon/favicon-128.png?v=3"},
            {"id" : "https://www.chip.de/rss/rss_topnews.xml", "name": "Chip Online", "activated" : true, "icon": "https://www.chip.de/fec/assets/favicon/apple-touch-icon.png?v=01"},
            {"id" : "https://www.theguardian.com/world/rss", "name": "The Guardian", "activated" : true, "icon":  "https://assets.guim.co.uk/images/favicons/6a2aa0ea5b4b6183e92d0eac49e2f58b/57x57.png"}]
        property var defaultActions: [{"id" : actionType.ShowDialer, "name" : qsTr("Show Dialer"), "activated" : true},
            {"id" : actionType.OpenCam, "name": qsTr("Camera"), "activated" : true},
            {"id" : actionType.ShowGallery, "name": qsTr("Gallery"), "activated" : true},
            {"id" : actionType.ShowCalendar, "name": qsTr("Agenda"), "activated" : true},
            {"id" : actionType.CreateEvent, "name": qsTr("Create Event"), "activated" : false},
            {"id" : actionType.ShowNotes, "name": qsTr("Show Notes"), "activated" : true},
            {"id" : actionType.ShowNews, "name": qsTr("Recent News"), "activated" : true},
            {"id" : actionType.ShowThreads, "name": qsTr("Recent Threads"), "activated" : true},
            {"id" : actionType.ShowContacts, "name": qsTr("Recent People"), "activated" : true},
            {"id" : actionType.Redial, "name" : qsTr("Redial"), "activated" : true}]
        property var timeStamp: 0
        property var lastCheckOfThreads: 0
        property var lastCheckOfCalls: 0
        property var redirectCount: 0
        property var maxRedirectCount: 1
        property bool keepLastIndex: false

        onCurrentIndexChanged: {
            console.debug("MainView | Index changed to " + currentIndex)
            switch (currentIndex) {
                case swipeIndex.Apps:
                    appGrid.children[0].item.updateNotifications()
                    break
                case swipeIndex.Preferences:
                    settingsPage.children[0].item.updateAvailablePlugins()
                    AN.SystemDispatcher.dispatch("volla.launcher.securityStateAction", {})
                    break
                default:
                    // Nothing to do
            }
        }

        onBackgroundOpacityChanged: {
            updateGridView("backgroundOpacity", backgroundOpacity)
        }

        Item {
            id: settingsPage

            Loader {
                id: settingsPageLoader
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Settings.qml", mainView)
            }
        }

        Item {
            id: appGrid

            Loader {
                id: appGridLoader
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/AppGrid.qml", mainView)
            }
        }

        Item {
            id: springboard

            Loader {
                id: springboardLoader
                anchors.fill: parent
                sourceComponent: Qt.createComponent("/Springboard.qml", mainView)
            }
        }

        function updateSpringboard(text, selectedObj) {
            console.log("MainView | Uodate springboar with text '" + text + "'")
            currentIndex = swipeIndex.Springboard
            var item = itemAt(swipeIndex.Springboard)
            if (selectedObj !== undefined) {
                item.children[0].item.selectedObj = selectedObj
            }
            item.children[0].item.textInputArea.text = text
        }

        function updateShortcutMenuState(opened) {
            console.log("MainView | Update shortcut menu state: '" + opened + "'")
            currentIndex = swipeIndex.Springboard
            var item = itemAt(swipeIndex.Springboard)
            item.children[0].item.updateShortcutMenuState(opened)
        }

        function updateCollectionPage(mode) {
            console.log("MainView | New collection mode: " + mode)
            if (count === swipeIndex.Springboard + 1) {
                var item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                item.children[0].sourceComponent = Qt.createComponent("/Collections.qml", mainView)
                addItem(item)
            } else {
                 while (count > swipeIndex.Collections + 1) {
                    removeItem(swipeIndex.Collections + 1)
                }
                item = itemAt(swipeIndex.Collections)
            }
            currentIndex = swipeIndex.Collections
            item.children[0].item.updateCollectionPage(mode)
        }

        function updateConversationPage(mode, id, name) {
            console.log("MainView | Will update conversation page")
            if (count === swipeIndex.Collections + 1) {
                var item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                addItem(item)
            } else {
                while (count > swipeIndex.ConversationOrNewsOrDetails + 1) {
                    removeItem(swipeIndex.ConversationOrNewsOrDetails + 1)
                }
                item = itemAt(swipeIndex.ConversationOrNewsOrDetails)
            }
            item.children[0].sourceComponent = Qt.createComponent("/Conversation.qml", mainView)
            currentIndex++
            updateSpinner(true)
            item.children[0].item.updateConversationPage(mode, id, name)
        }

        function updateDetailPage(mode, id, author, date, title, hasBadge) {
            console.log("MainView | Will update detail page")
            switch (currentIndex) {
                case swipeIndex.Collections:
                    console.log("MainView | Current page is a collection")
                    if (count > swipeIndex.Collections + 1) {
                        var item = itemAt(swipeIndex.ConversationOrNewsOrDetails)
                        if (item.children[0].item.objectName !== "detailPage") {
                            console.log("MainView | Create detail page")
                            item.children[0].sourceComponent = Qt.createComponent("/Details.qml", mainView)
                            while (count > swipeIndex.ConversationOrNewsOrDetails + 1) {
                                removeItem(swipeIndex.ConversationOrNewsOrDetails + 1)
                            }
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
                            while (count > swipeIndex.Details + 1) {
                                removeItem(swipeIndex.Details + 1)
                            }
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
            currentIndex++
            item.children[0].item.updateDetailPage(mode, id, author, date, title, hasBadge)
        }

        function updateNewsPage(mode, id, name, icon) {
            console.log("MainView | Will update news page")
            if (count === swipeIndex.Collections + 1) {
                var item = Qt.createQmlObject('import QtQuick 2.12; Item {Loader {anchors.fill: parent}}', mainView, "dynamicQml")
                addItem(item)
            } else {
                while (count > swipeIndex.ConversationOrNewsOrDetails + 1) {
                    removeItem(swipeIndex.ConversationOrNewsOrDetails + 1)
                }
                item = itemAt(swipeIndex.ConversationOrNewsOrDetails)
            }
            item.children[0].sourceComponent = Qt.createComponent("/Feed.qml", mainView)
            currentIndex++
            item.children[0].item.updateFeedPage(mode, id, name, icon)
        }

        function showToast(message) {
            toast.text = message
            toast.show()
        }

        function switchTheme(theme, updateLockScreen) {
            settings.theme = theme
            if (settings.sync) {
                settings.sync()
            }
            console.log("MainView | Swith theme to " + theme + ", " + settings.theme)
            switch (theme) {
            case mainView.theme.Dark:
                Universal.theme = Universal.Dark
                mainView.backgroundOpacity = 1.0
                mainView.backgroundColor = "black"
                mainView.fontColor = "white"
                break
            case mainView.theme.Light:
                Universal.theme = Universal.Light
                mainView.backgroundOpacity = 1.0
                mainView.backgroundColor = "white"
                mainView.fontColor = "black"
                break
            case mainView.theme.DarkTranslucent:
                Universal.theme = Universal.Dark
                mainView.backgroundOpacity = 0.3
                mainView.backgroundColor = "transparent"
                mainView.fontColor = "white"
            break
            case mainView.theme.LightTranslucent:
                Universal.theme = Universal.Light
                mainView.backgroundOpacity = 0.3
                mainView.backgroundColor = "transparent"
                mainView.fontColor = "black"
                break
            default:
                console.log("MainView | Not supported theme: " + theme)
                break
            }
            var item = itemAt(swipeIndex.Springboard)
            item.children[0].item.updateHeadlineColor()

            AN.SystemDispatcher.dispatch("volla.launcher.colorAction", { "value": theme, "updateLockScreen": updateLockScreen})
        }

        // todo: Improve display date and time with third party library
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
                return date.toDateString() + " " + date.getHours() + ":0" + date.getMinutes()
            } else {
                return date.toDateString() + " " + date.getHours() + ":" + date.getMinutes()
            }
        }

        function getContacts() {
            if (mainView.contacts === undefined) {
                var contactsStr = contactsCache.readPrivate()
                mainView.contacts = contactsStr.length === 0 ? new Array : JSON.parse(contactsStr)
            }
            return mainView.contacts
        }

        function getApps() {
            return appGrid.children[0].item.getAllApps()
        }

        function getFeeds() {
            var channels = feeds.read()
            console.log("MainView | Retrieved feeds: " + channels.lenth)
            return channels.length > 0 ? JSON.parse(channels) : mainView.defaultFeeds
        }

        function updateFeed(channelId, isActive, sAction, newChannel) {
            console.log("MainView | Will update channel: " + channelId + " with properties " + newChannel)
            var channels = getFeeds()
            var channel
            var matched = false
            var i
            for (i = 0; i < channels.length; i++) {
                channel = channels[i]
                if (channel["id"] === channelId) {
                    matched = true
                    channel["activated"] = isActive
                    break
                }
            }
            switch (sAction) {
                case mainView.settingsAction.CREATE:
                    if (matched === false) {
                        channels.push(newChannel)
                        console.log("MainView | Did store feeds: " + feeds.write(JSON.stringify(channels)))
                        showToast(qsTr("New Subscrption") + ": " + newChannel.name)
                    } else {
                        showToast(qsTr("You have already subscribed the feed"))
                    }
                    break
                case mainView.settingsAction.UPDATE:
                    if (matched === true) {
                        channels[i] = channel
                        console.log("MainView | Did store feeds: " + feeds.write(JSON.stringify(channels)))
                    }
                    break
                case mainView.settingsAction.REMOVE:
                    if (matched === true) {
                        channels.splice(i, 1)
                        console.log("MainView | Did store feeds: " + feeds.write(JSON.stringify(channels)))
                    }
                    break
                default:
                    break
            }
        }

        function updateRecentNews(channelId, newsId) {
            console.log("MainView | Will update recent news : " + channelId + " with newa " + newsId)
            if (channelId === undefined || newsId === undefined) {
                mainView.showToast(qsTr("Invalid news ID"))
            }
            var channels = getFeeds()
            var channel
            var matched = false
            var i
            for (i = 0; i < channels.length; i++) {
                channel = channels[i]
                if (channel["id"] === channelId) {
                    matched = true
                    channel["recent"] = newsId
                    console.log("MainView | Did store feeds: " + feeds.write(JSON.stringify(channels)))
                    break
                }
            }
        }

        function checkAndAddFeed(url) {
            console.log("MainView | Will check and update feeds")
            var doc = new XMLHttpRequest();
            doc.onreadystatechange = function() {
                if (doc.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                    console.log("MainView | Received header status feed url: " + doc.status);
                    if (doc.status === 301) {
                        var redirectUrl = doc.getResponseHeader("Location")
                        console.log("MainView | Redirect to " + redirectUrl)
                        if (maxRedirectCount - redirectCount > 0) {
                            redirectCount = redirectCount + 1
                            //checkAndAddFeed(redirectUrl)
                        } else {
                            redirectCount = 0
                            mainView.showToast(qsTr("Error because of too much redirects"))
                            doc.abort()
                        }
                    }
                    else if (doc.status >= 400) {
                        redirectCount = 0
                        mainView.showToast(qsTr("Could not load feed: " + doc.statusText))
                        doc.abort()
                    }
                } else if (doc.readyState === XMLHttpRequest.DONE) {
                    if (doc.responseXML === null) {
                        console.log("MainView | No valid XML for feed: " + doc.responseText)
                        mainView.showToast(qsTr("Could not load a valid feed"))
                        doc.abort()
                    } else {
                        var rss = doc.responseXML.documentElement
                        var channel
                        if (rss.nodeName === "feed") {
                            channel = rss
                        } else {
                            for (var i = 0; i < rss.childNodes.length; ++i) {
                                if (rss.childNodes[i].nodeName === "channel" || rss.childNodes[i].nodeName === "feed") {
                                    channel = rss.childNodes[i]
                                    break
                                }
                            }
                        }
                        if (channel === undefined) {
                            console.log("MainView | Missing rss channel")
                            mainView.showToast(qsTr("Invalid RSS feed: ") + url)
                            return
                        }
                        var feed = new Object

                        feed.id = url
                        feed.activated = true
                        for (i = 0; i < channel.childNodes.length; ++i) {
                            if (channel.childNodes[i].nodeName === "title") {
                                var childNode = channel.childNodes[i]
                                var textNode = childNode.firstChild
                                feed.name = textNode.nodeValue
                            } else if (channel.childNodes[i].nodeName === "logo") {
                                childNode = channel.childNodes[i]
                                textNode = childNode.firstChild
                                feed.icon = textNode.nodeValue
                            }
                        }

                        if (feed.icon !== undefined) {
                            mainView.updateFeed(feed.id, true, mainView.settingsAction.CREATE, feed)
                            return
                        }

                        var baseUrl = getBaseUrl(url)
                        var htmlRequest = new XMLHttpRequest();
                        htmlRequest.onreadystatechange = function() {
                            if (htmlRequest.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                                console.log("MainView | Received header status for news homepage: " + htmlRequest.status);
                                if (htmlRequest.status !== 200) {
                                    console.log("MainView | Couldn't load feed homepage. Will take fallback for icon")
                                    // todo: solution for fallback. ico not supported.
                                    feed.icon = baseUrl + "/favicon.ico"
                                    mainView.updateFeed(feed.id, true, mainView.settingsAction.CREATE, feed)
                                    return
                                }
                            } else if (htmlRequest.readyState === XMLHttpRequest.DONE) {
                                var html = htmlRequest.responseText
                                feed.icon = getFavicon(baseUrl, html)
                                mainView.updateFeed(feed.id, true, mainView.settingsAction.CREATE, feed)
                                return
                            }
                        }
                        htmlRequest.open("GET", baseUrl)
                        htmlRequest.send()
                    }
                }
            }
            doc.open("GET", url)
            doc.send()
        }

        function getBaseUrl(url) {
            var urlPattern = /(.+:\/\/)?([^\/]+)(\/.*)*/i
            var urlArr = urlPattern.exec(url)
            urlArr = urlArr[2].split(".")
            var baseUrl = "https://www." + urlArr[urlArr.length - 2] + "." + urlArr[urlArr.length - 1]
            console.log("MainView | base url for icon is " + baseUrl)
            return baseUrl
        }

        function getFavicon(baseUrl, pageSource) {
            var pattern = /<link\n?.+\n?.*rel="((apple-touch-)|(shortcut\s))?icon"\n?.+\n?.*>/i
            var link = pattern.exec(pageSource)
            if (link !== undefined && link !== null) {
                pattern = /href="\S+"/i
                link = pattern.exec(link).toString()
                var length = link.length - 1
                link = link.slice(6, length)
                if (!link.startsWith("http")) {
                    link = baseUrl + link
                }
                console.log("MainView | Identified feed icon: " + link)
                return link
            } else {
                console.log("MainView | Missing header of feed homepage. Will take fallback for icon")
                return baseUrl + "/favicon.ico"
            }
        }

        function getActions() {
            var actions = shortcuts.read()
            console.log("MainView | Retrieved shortcuts: " + actions)
            var actionArr = actions.length > 0 ? JSON.parse(actions) : mainView.defaultActions
            var find = actionArr.find(a => a.id === actionType.Redial)
            if (find === undefined) actionArr.push({"id" : actionType.Redial, "name" : qsTr("Redial"), "activated" : true})
            return actionArr
        }

        function updateAction(actionId, isActive, sAction, newAction) {
            console.log("MainView | Will update shortcut: " + actionId + " with properties " + newAction)
            var actions = getActions()
            var action
            var matched = false
            var i
            var stored = false
            for (i = 0; i < actions.length; i++) {
                action = actions[i]
                if (action["id"] === actionId) {
                    matched = true
                    action["activated"] = isActive
                    break
                }
            }
            switch (sAction) {
                case mainView.settingsAction.CREATE:
                    if (matched === false) {
                        actions.push(newAction)
                        showToast(qsTr("New shortcut") + ": " + newAction.name)
                    } else {
                        showToast(qsTr("You have alresdy added the shortcut"))
                    }
                    break
                case mainView.settingsAction.UPDATE:
                    if (matched === true) {
                        actions[i] = action
                    } else if (actionId === actionType.Redial) {
                        actions.push({ "id": actionType.Redial, "name": qsTr("Redial"), "activated" : isActive })
                    }
                    break
                case mainView.settingsAction.REMOVE:
                    if (matched === true) {
                        actions.splice(i, 1)
                    }
                    break
                default:
                    break
            }
            stored = shortcuts.write(JSON.stringify(actions))
            console.log("MainView | Did store Shortcut: " + stored)

            springboard.children[0].item.updateShortcuts(actions)
            return stored
        }

        function updateWidgets(widgetId, isVisible) {
            springboard.children[0].item.updateWidgets(widgetId, isVisible)
        }

        function getSearchMode() {
            return settings.searchMode
        }

        function updateSearchMode(searchMode) {
            settings.searchMode = searchMode
            if (settings.sync) {
                settings.sync()
            }
        }

        function getNotes() {
            if (notes.length === 0) var noteStr = notesStore.read()
            return noteStr !== undefined && noteStr.length > 0 ? JSON.parse(noteStr) : notes
        }

        function updateNote(noteId, content, pinned) {
            //console.debug("MainView | Update Note: " + noteId + ", " + content + ", " + pinned)
            var notesArr = mainView.getNotes()
            var note
            var i = 0
            while (noteId !== undefined && i < notesArr.length && note === undefined) {
                if (notesArr[i]["id"] === noteId) note = notesArr[i]
                i++
            }
            if (note !== undefined) {
                console.log("MainView | Existing note: " + note)
                note["content"] = content
                note["date"] = new Date().valueOf()
                note["pinned"] = pinned
                notesArr[i-1] = note
            } else {
                console.log("MainView | Create note")
                note = new Object
                note["id"] = noteId === undefined ? new Date().valueOf() : noteId
                note["content"] = content
                note["date"] = new Date().valueOf()
                note["pinned"] = false
                notesArr.push(note)
            }
            console.debug("MainView | New JSON: " + JSON.stringify(notesArr))
            notesStore.write(JSON.stringify(notesArr))
            notes = notesArr
            if (mainView.count > mainView.swipeIndex.Collections) {
                var item = itemAt(swipeIndex.Collections)
                item.children[0].item.updateCollectionPage(mainView.collectionMode.Notes)
            }
        }

        function removeNote(id) {
            console.log("MainView | Remove note " + id)
            var notesArr = mainView.getNotes()
            var index = notesArr.findIndex( element => {
                if (element.id === id) {
                    return true;
                }
            })
            if (index > -1) {
                notesArr.splice(index, 1)
                notesStore.write(JSON.stringify(notesArr))
                notes = notesArr
            }
            updateCollectionPage(mainView.collectionMode.Notes)
        }

        function updateSpinner(shouldRun) {
            if (!(isLoadingContacts && !shouldRun)) {
                spinner.running = shouldRun
            }
        }

        function updateGridView(key, value) {
            var item = itemAt(swipeIndex.Apps)
            item.children[0].item.updateAppLauncher(key, value)
        }

        function updateSettings(key, value) {
            if (key === "blurEffect") {
                settings.blurEffect = value
                fastBlur.radius = value
            } else if (key === "fullscreen") {
                settings.fullscreen = value
                if (value) {
                    appWindow.visibility = 5
                } else {
                    appWindow.visibility = 2
                }
            } else if (key === "useHapticMenus") {
                settings.useHapticMenus = value
                mainView.useVibration = value
            } else if (key === "leftHandedMenu") {
                var previousValue = settings.leftHandedMenu
                settings.leftHandedMenu = value
                // If switching from left-handed to right-handed (true -> false), refresh Springboard
                if (previousValue === true && value === false) {
                    console.log("MainView | Refreshing Springboard due to left->right menu switch")
                    springboardLoader.active = false
                    springboardLoader.active = true
                }
            } else if (key === "showAppsAtStartup") {
                settings.showAppsAtStartup = value
            } else if (key === "activateSignal") {
                settings.signalIsActivated = value
            } else if (key === "customAccentColor") {
                settings.customAccentColor = value
                mainView.accentColor = value.length > 0 ? value : Universal.accent
                mainView.accentTextColor = getContrastColor(mainView.accentColor)
            }
            if (settings.sync) {
                settings.sync()
            }
        }

        function resetActions() {
            shortcuts.write(JSON.stringify(defaultActions))
            showToast(qsTr("Reset successful"))
        }

        function resetFeeds() {
            feeds.write(JSON.stringify(defaultFeeds))
            showToast(qsTr("Reset successful"))
        }

        function resetLauncher() {
            AN.SystemDispatcher.dispatch("volla.launcher.resetAction", {})
        }

        function resetContacts() {
            console.debug("MainView | Reset contacts")
            settings.lastContactsCheck = 0.0
            AN.SystemDispatcher.dispatch("volla.launcher.checkContactAction", {"timestamp": settings.lastContactsCheck })
        }

        function getInstalledPlugins() {
            pluginStore.setSource("installedPlugins.json")
            var pluginsStr = pluginStore.readPrivate()
            return pluginsStr !== undefined && pluginsStr.length > 0 ? JSON.parse(pluginsStr) : new Array
        }

        function getInstalledPluginSource(pluginId) {
            console.debug("MainView | plugin id: " + pluginId)
            pluginStore.setSource(pluginId + "_plugin.qml")
            return pluginStore.readPrivate()
        }

        function updateInstalledPlugins(pluginMetadata, isEnabled, callback) {
            var installedPlugins = getInstalledPlugins()
            var pluginSource = pluginMetadata["id"] + "_plugin.qml"
            if (isEnabled) {
                var xmlRequest = new XMLHttpRequest();
                xmlRequest.onreadystatechange = function() {
                    if (xmlRequest.readyState === XMLHttpRequest.DONE) {
                        console.debug("MainView | got plugin request responce")
                        if (xmlRequest.status === 200) {
                            console.log("MainView | plugin responste status 200")
                            var plugin = xmlRequest.responseText
                            pluginStore.setSource(pluginSource)
                            console.debug("MainView | Length: " + plugin.length)
                            pluginStore.writePrivate(plugin)
                            console.debug("MainView | Read back: " + pluginStore.readPrivate().length)
                            installedPlugins.push(pluginMetadata)
                            pluginStore.setSource("installedPlugins.json")
                            pluginStore.writePrivate(JSON.stringify(installedPlugins))
                            springboard.children[0].item.addPlugin(plugin, pluginMetadata.id)
                            callback(true)
                        } else {
                            mainView.showToast(qsTr("Couldn't load plugin"))
                            console.error("Settings | Error retrieving plugin: ", xmlRequest.status, xmlRequest.statusText)
                            callback(false)
                        }
                    }
                };
                xmlRequest.open("GET", pluginMetadata.downloadUrl)
                console.debug("Mainview | Sending plugin request")
                xmlRequest.send();
            } else {
                installedPlugins = installedPlugins.filter( el => el.id !== pluginMetadata.id )
                pluginStore.setSource("installedPlugins.json")
                pluginStore.writePrivate(JSON.stringify(installedPlugins))
                springboard.children[0].item.removePlugin(pluginMetadata.id)
                callback(true)
            }
        }

        function checkDefaultApps(apps) {
            console.debug("MainView | Will check apps")
            console.debug(apps.filter( el => el.package === "org.fossify.gallery" ).length)
            console.debug(apps.filter( el => el.package === "org.fossify.calendar" ).length)

            mainView.galleryApp = apps.filter( el => el.package === "org.fossify.gallery" ).length > 0 ?
                        "org.fossify.gallery" : "com.simplemobiletools.gallery.pro"
            mainView.calendarApp = apps.filter( el => el.package === "org.fossify.calendar" ).length > 0 ?
                        "org.fossify.calendar" : "com.simplemobiletools.calendar.pro"
        }

        function isActiveSignal() {
            return settings.signalIsActivated
        }

        WorkerScript {
            id: contactsWorker
            source: "scripts/contacts.mjs"
            onMessage: {
                console.log("MainView | Contacts worker message received: " + messageObject.contacts.length)
                if (messageObject.contacts.length !== 0) {
                    var d = new Date()
                    console.log("MainView | Read contacts did take " + ((d.valueOf() - mainView.timeStamp.valueOf()) / 1000) + " seconds")
                    mainView.contacts = messageObject.contacts
                }
            }
        }

        Connections {
            target: AN.SystemDispatcher
            // @disable-check M16
            onDispatched: {
                if (type === "volla.launcher.contactResponse") {
                    console.log("MainView | onDispatched: " + type)
                    console.log("MainView | Contacts " + message["blockStart"] + " to " + message["blockEnd"])
                    mainView.loadingContacts = mainView.loadingContacts.concat(message["contacts"])
                    if (mainView.loadingContacts.length === message["contactsCount"]) {
                        var d = new Date()
                        console.log("MainView | Retrieving contacts did take " + (d.valueOf() - mainView.timeStamp.valueOf()) + " seconds")
                        mainView.loadingContacts = mainView.loadingContacts.filter(function(contact) {
                            return contact["name"] !== undefined
                        })
                        mainView.loadingContacts.sort(function(a, b) {
                            var x = a["name"].toLowerCase(),
                                y = b["name"].toLowerCase()
                            return x === y ? 0 : x > y ? 1 : -1;
                        })
                        mainView.contacts = mainView.loadingContacts.slice()
                        mainView.loadingContacts.lemgh = 0
                        console.log("MainView | Did store contacts: " + contactsCache.writePrivate(JSON.stringify(mainView.contacts)))
                        mainView.isLoadingContacts = false
                        mainView.updateSpinner(false)
                        settings.lastContactsCheck = new Date().valueOf()
                        if (settings.sync) {
                            settings.sync()
                        }
                        console.log("MainView | New contact timestamp " + settings.lastContactsCheck)
                    }
                } else if (type === "volla.launcher.checkContactResponse") {
                    console.log("MainView | onDispatched: " + type)
                    if (message["needsSync"] && !mainView.isLoadingContacts) {
                        console.log("MainView | Need to sync contacts")
                        mainView.timeStamp = new Date()
                        mainView.loadingContacts = new Array
                        mainView.isLoadingContacts = true
                        mainView.updateSpinner(true)
                        AN.SystemDispatcher.dispatch("volla.launcher.contactAction", {})
                    } else if (mainView.contacts.length === 0 && !mainView.isLoadingContacts) {
                        mainView.timeStamp = new Date()
                        var contactsStr = contactsCache.readPrivate()
                        console.log("MainView | Did read contacts with length " + contactsStr.length)
                        if (contactsStr !== undefined) contactsWorker.sendMessage({'contactsStr': contactsStr })
                    }
                } else if (type === "volla.launcher.wallpaperResponse") {
                    console.log("MainView | onDispatched: " + type)

                    if (message["wallpaper"] !== undefined) {
                        mainView.wallpaper = "data:image/png;base64," + message["wallpaper"]
                        mainView.wallpaperId = message["wallpaperId"]
                    } else if (message["wallpaperId"] === undefined) {
                        mainView.wallpaper = "/images/Summer_Mode_2x.png"
                        mainView.wallpaperId = "default"
                    }
                } else if (type === 'volla.launcher.receiveTextResponse') {
                    console.log("MainView | onDispatched: " + type)
                    var text = message["sharedText"]
                    var urlregex = /^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$/
                    if (urlregex.test(text.trim())) {
                        mainView.checkAndAddFeed(text)
                    } else {
                        console.log("MainView | Invalid RSS feed url")
                    }
                } else if (type === "volla.launcher.uiModeResponse") {
                    mainView.switchTheme(message["uiMode"], false)
                } else if (type === "volla.launcher.messageResponse") {
                    console.log("MainView | onDispatched: " + type)
                    console.log("MainView | message: " + message["text"] + ", " + mainView.notifications[message["text"]])
                    if (!message["sent"]) {
                        mainView.showToast(qsTr(mainView.notifications[message["text"]]))
                    } else {
                        mainView.showToast(qsTr(mainView.notifications[message["text"]]))
                    }
                } else if (type === "volla.launcher.uiModeChanged") {
                    if (message["uiMode"] !== settings.theme) {
                        settings.theme = message["uiMode"]
                        settings.sync()
                        if (message["uiMode"] === mainView.theme.Light) {
                            if (settings.theme === mainView.theme.LightTranslucent || settings.theme === mainView.theme.DarkTranslucent) {
                                mainView.switchTheme(mainView.theme.LightTranslucent, false)
                            } else {
                                mainView.switchTheme(mainView.theme.Light, true)
                            }

                        } else if (message["uiMode"] === mainView.theme.Dark) {
                            if (settings.theme === mainView.theme.LightTranslucent || settings.theme === mainView.theme.DarkTranslucent) {
                                mainView.switchTheme(mainView.theme.DarkTranslucent, false)
                            } else {
                                mainView.switchTheme(mainView.theme.Dark, true)
                            }
                        }
                    }
                } else if (type === "volla.launcher.checkSttAvailabilityResponse") {
                    console.debug("MainView | STT activation status: " + message["isActivated"])
                    if (!message["isActivated"]) {
                        var component = Qt.createComponent("/SttSetup.qml")
                        var properties = { "fontSize" : 18, "innerSpacing" : 22 }
                        if (component.status !== Component.Ready) {
                            if (component.status === Component.Error)
                                console.debug("MainView | Error: "+ component.errorString() );
                        }
                        var object = component.createObject(mainView, properties)
                        object.open()
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: spinner
        height: 50
        width: 50
        anchors.centerIn: parent
        running: false
        z: 5

        onRunningChanged: {
            console.log("MainView | Spinner running changed to " + running)
        }
    }

    Settings {
        id: settings
        property int theme: mainView.theme.Dark
        property int searchMode: mainView.searchMode.StartPage
        property bool fullscreen: false
        property bool firstStart: true
        property bool sttChecked: false
        property bool signalIsActivated: false
        property bool useColoredIcons: false
        property bool showAppsAtStartup: false
        property bool useHapticMenus: true
        property bool leftHandedMenu: false
        property double blurEffect: 60.0
        property double lastContactsCheck: 0.0
        property string customAccentColor: ""

        function checkCustomParameters() {
            var rawPresets = presets.readPresets()

            for (var i = 0; i < rawPresets.split("\n").length; i++) {
                console.debug("AppWindow | presets " + rawPresets.split("\n")[i])
            }

            if (rawPresets !== undefined && rawPresets.length > 0) {
                var presetDict = JSON.parse(rawPresets)

                if (presetDict.color !== undefined && presetDict.color.accent !== undefined) {
                    console.debug("AppWindow | Set accent color from "+ Universal.accent + " to " + presetDict.color.accent)
                    mainView.accentColor = presetDict.color.accent
                }
                if (presetDict.feeds !== undefined && presetDict.feeds.length > 0) {
                    console.debug("AppWindow | Set default feeds to " + presetDict.feeds)
                    mainView.defaultFeeds = presetDict.feeds
                    if (settings.firstStart) mainView.resetFeeds()
                }
                if (presetDict.quickmenu !== undefined && presetDict.quickmenu.length > 0) {
                    console.debug("AppWindow | Set default actions to " + presetDict.quickmenu)
                    var isValid = true
                    Object.keys(presetDict.quickmenu).forEach(function(key) {
                        if (!isNaN(presetDict.quickmenu[key])) isValid = false
                    })
                    if (isValid) {
                        mainView.defaultActions = presetDict.quickmenu
                        if (presetDict.firstStart) mainView.resetActions()
                    } else {
                        console.debug("AppWindow | Preset actions for quick menu are invalid")
                    }
                }
                if (presetDict.theme !== undefined && settings.firstStart) {
                    console.debug("AppWindow | Set default theme to " + presetDict.theme)
                    settings.theme = presetDict.theme
                }
                if (presetDict.searchengine !== undefined && presetDict.searchengine.url !== undefined && presetDict.searchengine.name !== undefined) {
                    console.debug("AppWindow | Set additional search engine to "+ presetDict.searchengine.name)
                    mainView.searchEngineName = presetDict.searchengine.name
                    mainView.searchEngineUrl = presetDict.searchengine.url
                    if (settings.firstStart) {
                        console.debug("AppWindow | Set default search engine to "+ presetDict.searchengine.name)
                        settings.searchMode = mainView.searchMode.Custom
                    }
                }
            }
        }

        Component.onCompleted: {
            console.debug("MainView | Settings onCompleted")
            checkCustomParameters()
            
            if (settings.customAccentColor.length > 0) {
                mainView.accentColor = settings.customAccentColor
                mainView.accentTextColor = getContrastColor(mainView.accentColor)
            }

            if (Universal.theme !== settings.theme) {
                mainView.switchTheme(settings.theme, firstStart)
            } else {
                AN.SystemDispatcher.dispatch("volla.launcher.colorAction", { "value": theme, "updateLockScreen": firstStart})
            }
            if (settings.firstStart) {
                console.debug("AppWindow | ", "Will start tutorial")
                var component = Qt.createComponent("/OnBoarding.qml")
                var properties = { "mainView" : mainView, "innerSpacing" : mainView.innerSpacing }
                if (component.status !== Component.Ready) {
                    if (component.status === Component.Error)
                        console.debug("MainView | Error: "+ component.errorString() );
                }
                var object = component.createObject(mainView, properties)
                object.open()
                settings.firstStart = false
            } else if (!settings.sttChecked) {
                console.debug("MainView", "Will check stt availability")
                settings.sttChecked = true
                AN.SystemDispatcher.dispatch("volla.launcher.checkSttAvailability", {})
            }
            if (fullscreen) {
                appWindow.visibility = 5
            }
            if (signalIsActivated) {
                AN.SystemDispatcher.dispatch("volla.launcher.signalEnable", { "enableSignal": signalIsActivated})
            }
            mainView.useVibration = useHapticMenus
            mainView.useColoredIcons = useColoredIcons
            if (settings.sync) {
                settings.sync()
            }
        }
    }

    // @disable-check M300
    AN.Toast {
        id: toast
        text: qsTr("Not yet supported")
        longDuration: true
    }

    FileIO {
        id: presets
    }

    FileIO {
        id: feeds
        source: ".feeds.json"
        onError: {
            console.log("MainView | Feed settings error: " + msg)
        }
    }

    FileIO {
        id: shortcuts
        source: ".shortcuts.json"
        onError: {
            console.log("MainView | Shortcut settings error: " + msg)
        }
    }

    FileIO {
        id: notesStore
        source: ".notes.json"
        onError: {
            console.log("Collections | Notes file error: " + msg)
        }
    }

    FileIO {
        id: contactsCache
        source: "contacts.json"
        onError: {
            console.log("MainView | Contacts cache error: " + msg)
        }
    }

    FileIO {
        id: pluginStore
        source: "pluginStore.json"
        onError: {
            console.log("MainView | plugin store error: " + msg)
        }
    }
}
