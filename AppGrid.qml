import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtQuick.XmlListModel 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN

Page {
    id: appLauncher
    anchors.fill: parent

    property string textInput
    property real labelPointSize: 16
    property var iconMap: {
        "com.simplemobiletools.dialer": "/icons/dial-phone@4x.png",
        //"com.simplemobiletools.smsmessenger": "/icons/message@4x.png",
        "com.android.mms" : "/icons/message@4x.png",
        "com.android.messaging": "/icons/message@4x.png",
        "com.google.android.apps.messaging" : "/icons/message@4x.png",
        "net.osmand.plus": "/icons/route-directions-map@4x.png",
        "com.mediatek.camera": "/icons/camera@4x.png",
        "com.simplemobiletools.gallery.pro": "/icons/photo-gallery@4x.png",
        "com.simplemobiletools.contacts.pro": "/icons/people-contacts-agenda@4x.png",
        "com.simplemobiletools.clock": "/icons/clock@4x.png",
        "com.android.settings": "/icons/settings@4x.png",
        "com.simplemobiletools.calendar.pro": "/icons/calendar@4x.png",
        "com.simplemobiletools.filemanager.pro": "/icons/folder@4x.png",
        "org.telegram.messenger": "/icons/telegram@4x.png",
        "com.android.email": "/icons/email@4x.png",
        "com.google.android.gm": "/icons/email@4x.png",
        "com.Slack": "/icons/slack@4x.png",
        "com.simplemobiletools.notes.pro": "/icons/notes@4x.png",
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
        "com.simplemobiletools.calculator": "/icons/calculator@4x_104x104px.png",
        "com.android.calculator2": "/icons/calculator@4x_104x104px.png",
        "eu.siacs.conversations": "/icons/xmpp@4x_104x104px.png"
    }
    property var labelMap: {
        "org.mozilla.fennec_fdroid": "Browser",
        "com.google.android.gm" : "Mail",
        "at.bitfire.davdroid": "Sync",
        "hideme.android.vpn.noPlayStore": "VPN",
        "com.simplemobiletools.filemanager.pro": "Files",
        "com.aurora.store": "Store",
        "net.osmand.plus": "Maps",
        "com.volla.launcher": "Settings",
        "com.simplemobiletools.smsmessenger": "Messages",
        "com.android.fmradio" : "Radio",
        "de.baumann.weather": "Wetter",
    }
    property bool unreadMessages: false
    property bool newCalls: false
    property int appCount: 0

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    onTextInputChanged: {
        console.log("text input changed")
        gridModel.update(textInput)
        //xmlModel.update(textInput)
    }

    function updateAppLauncher(useColoredAppIcons) {
        settings.sync()
        gridView.desaturation = useColoredAppIcons ? 0.0 : 1.0
        gridView.forceLayout()
    }

    function updateNotifications() {
        AN.SystemDispatcher.dispatch("volla.launcher.callLogAction", {"is_read": 0})
        AN.SystemDispatcher.dispatch("volla.launcher.threadsCountAction", {"read": 0})
    }

    GridView {
        id: gridView
        anchors.fill: parent
        cellHeight: parent.width * 0.32
        cellWidth: parent.width * 0.25

        property var desaturation: settings.useColoredIcons ? 0.0 : 1.0

        model: gridModel

        currentIndex: -1

        header: Column {
            id: header
            width: parent.width
            Label {
                id: headerLabel
                topPadding: mainView.innerSpacing * 2
                x: mainView.innerSpacing
                text: qsTr("Apps")
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
            }
            TextField {
                id: textField
                padding: mainView.innerSpacing
                x: mainView.innerSpacing
                width: parent.width - mainView.innerSpacing * 2
                placeholderText: qsTr("Filter apps")
                color: mainView.fontColor
                placeholderTextColor: "darkgrey"
                font.pointSize: mainView.largeFontSize
                leftPadding: 0.0
                rightPadding: 0.0

                background: Rectangle {
                    color: "transparent"
                    border.color: "transparent"
                }
                Binding {
                    target: appLauncher
                    property: "textInput"
                    value: textField.displayText.toLowerCase()
                }

                Button {
                    id: deleteButton
                    text: "<font color='#808080'>×</font>"
                    font.pointSize: mainView.largeFontSize * 2
                    flat: true
                    topPadding: 0.0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    visible: textField.displayText !== ""

                    onClicked: {
                        textField.text = ""
                        textField.focus = false
                    }
                }
            }
            Rectangle {
                width: parent.width
                border.color: "transparent"
                color: "transparent"
                height: 1.1
            }
            //bottomPadding: mainView.innerSpacing / 2
        }

        delegate: Rectangle {
            id: gridCell
            width: parent.width * 0.25
            height: parent.width * 0.32
            color: "transparent"

            property var gradientColor: Universal.background
            property var overlayColor: Universal.foreground

            Rectangle {
                id: gridCircle
                anchors.top: gridButton.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.width * 0.6
                width: parent.width * 0.6
                color: Universal.foreground
                opacity: Universal.theme === Universal.Light ? 0.1 : 0.2
                radius: width * 0.5
            }

            Button {
                id: gridButton
                anchors.top: parent.top
                anchors.topMargin: parent.width * 0.08 // Adjustment
                topPadding: mainView.innerSpacing / 2
                width: parent.width
                text: model.label
                contentItem: Column {
                    spacing: gridCell.width * 0.25
                    Image {
                        id: buttonIcon
                        anchors.left: parent.left
                        anchors.leftMargin: gridCell.width * 0.25
                        source: model.package in appLauncher.iconMap ? Qt.resolvedUrl(appLauncher.iconMap[model.package])
                                                                     : "data:image/png;base64," + model.icon
                        width: gridButton.width * 0.35
                        height: gridButton.width * 0.35

                        ColorOverlay {
                            anchors.fill: buttonIcon
                            source: buttonIcon
                            color: gridCell.overlayColor
                            visible: model.package in appLauncher.iconMap
                        }
                    }
                    Label {
                        id: buttonLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: gridButton.width - mainView.innerSpacing
                        horizontalAlignment: contentWidth > gridButton.width - mainView.innerSpacing ? Text.AlignLeft : Text.AlignHCenter
                        text: gridButton.text
                        font.pointSize: appLauncher.labelPointSize
                        clip: mainView.backgroundOpacity === 1.0 ? true : false
                        elide: mainView.backgroundOpacity === 1.0 ? Text.ElideNone :  Text.ElideRight
                    }
                }
                flat:true
                background: Rectangle {
                    color: "transparent"
                    border.color: "transparent"
                }
                onClicked: {
                    if (gridView.currentIndex > -1) {
                        contextMenu.dismiss()
                        gridView.currentIndex = -1
                    } else if (model.package.length > 0) {
                        console.log("App " + model.label + " selected")
                        // As a workaround for a missing feature in the phone app
                        if (model.package === mainView.phoneApp) {
                            if (appLauncher.newCalls) {
                                AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp, "action": "log"})
                                AN.SystemDispatcher.dispatch("volla.launcher.updateCallsAsRead", { })
                            } else {
                                AN.SystemDispatcher.dispatch("volla.launcher.dialerAction", {"app": mainView.phoneApp})
                            }
                        } else {
                            AN.SystemDispatcher.dispatch("volla.launcher.runAppAction", {"appId": model.package})
                        }
                    }
                }
                onPressAndHold: {
                    gridView.currentIndex = index
                    contextMenu.popup(gridCell)
                }
            }

            Desaturate {
                anchors.fill: gridButton
                source: gridButton
                desaturation: gridView.desaturation
            }

            LinearGradient {
                id: labelTruncator
                height: parent.height
                width: parent.width //+ parent.width * 0.2
                start: Qt.point(parent.width - mainView.innerSpacing, 0)
                end: Qt.point(parent.width,0)
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#00000000"
                    }
                    GradientStop {
                        position: 1.0
                        color: gridCell.gradientColor
                    }
                }
                visible: mainView.backgroundOpacity === 1.0
            }

            Rectangle {
                id: notificationBadge
                visible: mainView.messageApp.includes(model.package) ? appLauncher.unreadMessages
                                                                     : model.package === mainView.phoneApp ? appLauncher.newCalls                                                               : false
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: (parent.width - parent.width * 0.6) * 0.5
                width: parent.width * 0.15
                height: parent.width * 0.15
                radius: height * 0.5
                color:  Universal.accent
            }
        }
    }

    Menu {
        id: contextMenu

        MenuItem {
            text: qsTr("Add to shortcuts")
            font.pointSize: appLauncher.labelPointSize
            leftPadding: mainView.innerSpacing
            rightPadding: mainView.innerSpacing
            topPadding: mainView.innerSpacing
            background: Rectangle {
                anchors.fill: parent
                color: Universal.accent
            }
            onClicked: {
                var idx = gridView.currentIndex
                console.log("AppGrid | Index " + idx + " selected for shortcuts");
                var app = gridModel.get(idx)
                console.log("AppGrid | App " + app["label"] + " selected for shortcuts");
                gridView.currentIndex = -1
                mainView.updateAction(app["package"],
                                      true,
                                      mainView.settingsAction.CREATE,
                                      {"id": app["package"], "name": qsTr("Open") + " " + app["label"], "activated": true} )
            }
        }
        MenuItem {
            text: qsTr("Open App")
            font.pointSize: appLauncher.labelPointSize
            leftPadding: mainView.innerSpacing
            rightPadding: mainView.innerSpacing
            bottomPadding: mainView.innerSpacing
            background: Rectangle {
                anchors.fill: parent
                color: Universal.accent
            }
            onClicked: {
                gridView.currentIndex = -1
                mainView.showToast("Will be implemented soon!")
            }
        }
    }

    ListModel {
        id: gridModel

        property var modelArr: []

        function prepareModel() {
            modelArr.forEach(function(app, i) {
                modelArr[i].label = modelArr[i].package in appLauncher.labelMap ? qsTr(appLauncher.labelMap[modelArr[i].package])
                                                                                : modelArr[i].label
            })
        }

        function update(text) {
            console.log("AppGrid | Update model with text input: " + text)

            var filteredGridDict = new Object
            var filteredGridItem
            var gridItem
            var found
            var i

            console.log("Model has " + modelArr.length + " elements")

            // filter model
            for (i = 0; i < modelArr.length; i++) {
                filteredGridItem = modelArr[i]
                var modelItemName = modelArr[i].label
                var modelItemId = modelArr[i].package
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    // console.log("Add " + modelItemName + " to filtered items")
                    filteredGridDict[modelItemId] = filteredGridItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemId = get(i).package
                existingGridDict[modelItemId] = true
            }

            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemId = get(i).package
                found = filteredGridDict.hasOwnProperty(modelItemId)
                if (!found) {
                    console.log("Remove " + modelItemId)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            var keys = Object.keys(filteredGridDict)
            keys.forEach(function(key) {
                found = existingGridDict.hasOwnProperty(key)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    // filteredGridItem = filteredGridDict[key]
                    console.log("Will append " + filteredGridItem.label)
                    append(filteredGridDict[key])
                }
            })

            sortModel()
        }

        function sortModel() {
            var n;
            var i;
            for (n = 0; n < count; n++) {
                for (i=n+1; i < count; i++) {
                    if (get(n).label.toLowerCase() > get(i).label.toLowerCase()) {
                        move(i, n, 1);
                        n = 0;
                    }
                }
            }
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.appCountResponse") {
                if (message["appCount"] !== appLauncher.appCount) {
                    console.log("AppGrid | Number of apps: " + message["appCount"], ", " + appLauncher.appCount)
                    appLauncher.appCount = message["appCount"]
                    mainView.updateSpinner(true)
                    AN.SystemDispatcher.dispatch("volla.launcher.appAction", new Object)
                }
            } else if (type === "volla.launcher.appResponse") {
                console.log("AppGrid | " + message["appsCount"] + " app infos received")
                settings.sync()
                gridModel.modelArr = message["apps"]
                gridModel.prepareModel()
                gridModel.update(textInput)
                mainView.updateSpinner(false)
            } else if (type === "volla.launcher.callLogResponse") {
                console.log("AppGrid | Missed calls: " + message["callsCount"])
                appLauncher.newCalls = message["callsCount"] > 0
            } else if (type === "volla.launcher.threadsCountResponse") {
                console.log("AppGrid | Unread messages: " + message["threadsCount"])
                appLauncher.unreadMessages = message["threadsCount"] > 0
            }
        }
    }

    Settings {
        id: settings
        property bool useColoredIcons: false

        onUseColoredIconsChanged: {
            console.log("Colered icons settings changed")
            gridView.desaturation = useColoredIcons ? 0.0 : 1.0
        }
    }
}
