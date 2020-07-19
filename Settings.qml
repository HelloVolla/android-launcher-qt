import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Universal 2.12
import Qt.labs.settings 1.0

Page {
    id: settingsPage
    anchors.fill: parent
    topPadding: mainView.innerSpacing

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: settingsColumn.height

        Column {
            id: settingsColumn
            width: parent.width

            Label {
                id: headerLabel
                padding: mainView.innerSpacing
                width: parent.width - 2 * mainView.innerSpacing
                text: qsTr("Settings")
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
                bottomPadding: mainView.innerSpacing
            }

            MouseArea {
                id: modeSettings
                width: parent.width
                implicitHeight: modeSettingsColumn.height
                preventStealing: true

                property var selectedMenuItem: modeSettingsTitle
                property bool menuState: false
                property double labelOpacity: 0.0

                Column {
                    id: modeSettingsColumn
                    width: parent.width

                    Label {
                        id: modeSettingsTitle

                        property var theme: themeSettings.theme

                        padding: mainView.innerSpacing
                        width: parent.width
                        text: qsTr("Dark Mode")
                        font.pointSize: mainView.largeFontSize
                        font.weight: modeSettings.menuState ? Font.Black : Font.Normal
                        color: modeSettings.menuState ? "white" : Universal.foreground
                        background: Rectangle {
                            anchors.fill: parent
                            color: modeSettings.menuState === true ? Universal.accent : "transparent"
                        }

                        Component.onCompleted: {
                            theme = themeSettings.theme
                            switch (themeSettings.theme) {
                            case mainView.theme.Dark:
                                text = qsTr("Dark Mode")
                                break
                            case mainView.theme.Light:
                                text = qsTr("Light Mode")
                                break
                            case mainView.theme.Translucent:
                                text = qsTr("Translucent Mode")
                                break
                            default:
                                console.log("Settings | Unknown theme selected: " + mainView.theme)
                            }
                        }
                    }
                    Button {
                        id: darkModeOption

                        property var theme: mainView.theme.Dark

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing
                        width: parent.width
                        visible: modeSettings.menuState
                        text: qsTr("Dark Mode")
                        contentItem: Text {
                            text: darkModeOption.text
                            font.pointSize: mainView.mediumFontSize
                            font.weight: modeSettings.selectedMenuItem === darkModeOption ? Font.Black : Font.Normal
                            color: "white"
                            opacity: modeSettings.labelOpacity
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: modeSettings.menuState ? Universal.accent : "transparent"
                        }
                    }
                    Button {
                        id: lightModeOption

                        property var theme: mainView.theme.Light

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing
                        width: parent.width
                        visible: modeSettings.menuState
                        text: qsTr("Light Mode")
                        contentItem: Text {
                            text: lightModeOption.text
                            font.pointSize: mainView.mediumFontSize
                            font.weight: modeSettings.selectedMenuItem === lightModeOption ? Font.Black : Font.Normal
                            color: "white"
                            opacity: modeSettings.labelOpacity
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: modeSettings.menuState ? Universal.accent : "transparent"
                        }
                    }
                    Button {
                        id: translucentModeOption

                        property var theme: mainView.theme.Translucent

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing * 2
                        width: parent.width
                        visible: modeSettings.menuState
                        text: qsTr("Translucent Mode")
                        contentItem: Text {
                            text: translucentModeOption.text
                            font.pointSize: mainView.mediumFontSize
                            font.weight: modeSettings.selectedMenuItem === translucentModeOption ? Font.Black : Font.Normal
                            color: "white"
                            opacity: modeSettings.labelOpacity
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: modeSettings.menuState ? Universal.accent : "transparent"
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.
                        onRunningChanged: {
                            if (!running && modeSettings.menuState) {
                                console.log("Settings | Switch on mode options labels")
                                modeSettings.labelOpacity = 1.0
                            } else if (running && !modeSettings.menuState) {
                                console.log("Settings | Switch off mode option labels")
                                modeSettings.labelOpacity = 0.0
                            }
                        }
                    }
                }

                Behavior on labelOpacity {
                    NumberAnimation {
                        duration: 250
                    }
                }

                onEntered: {
                    console.log("Settings | mouse entered")
                    preventStealing = !preventStealing
                    menuState = true
                }
                onCanceled: {
                    console.log("Settings | mouse cancelled")
                    preventStealing = !preventStealing
                    menuState = false
                    executeSelection()
                }
                onExited: {
                    console.log("Settings | mouse exited")
                    preventStealing = !preventStealing
                    menuState = false
                    executeSelection()
                }
                onMouseYChanged: {
                    var firstPoint = mapFromItem(darkModeOption, 0, 0)
                    var secondPoint = mapFromItem(lightModeOption, 0, 0)
                    var thirdPoint = mapFromItem(translucentModeOption, 0, 0)

                    if (mouseY > firstPoint.y && mouseY < firstPoint.y + darkModeOption.height) {
                        selectedMenuItem = darkModeOption
                    } else if (mouseY > secondPoint.y && mouseY < secondPoint.y + lightModeOption.height) {
                        selectedMenuItem = lightModeOption
                    } else if (mouseY > thirdPoint.y && mouseY < thirdPoint.y + translucentModeOption.height) {
                        selectedMenuItem = translucentModeOption
                    } else {
                        selectedMenuItem = modeSettingsTitle
                    }
                }

                function executeSelection() {
                    console.log("Settings | Current mode: " + Universal.theme + ", " + themeSettings.theme)
                    console.log("Settings | Execute mode selection: " + selectedMenuItem.text + ", " + selectedMenuItem.theme)
                    if (themeSettings.theme !== selectedMenuItem.theme && selectedMenuItem !== modeSettingsTitle) {
                        modeSettingsTitle.text = selectedMenuItem.text

                        // Todo: Update settings
                        console.log("Current Theme: " + themeSettings.theme)
                        themeSettings.theme = selectedMenuItem.theme
                        themeSettings.sync()
                        console.log("Updated Theme: " + themeSettings.theme)

                        switch (themeSettings.theme) {
                            case mainView.theme.Dark:
                                console.log("Enable dark mode")
                                mainView.switchTheme(mainView.theme.Dark)
                                break
                            case mainView.theme.Light:
                                console.log("Enable light mode")
                                mainView.switchTheme(mainView.theme.Light)
                                break
                            case mainView.theme.Translucent:
                                console.log("Enable translucent mode")
                                mainView.switchTheme(mainView.theme.Translucent)
                                break
                            default:
                                console.log("Settings | Unknown theme selected: " + themeSettings.theme)
                        }

                        selectedMenuItem = modeSettingsTitle
                    }
                }

                Settings {
                    id: themeSettings
                    property int theme: mainView.theme.Dark
                }
            }

            Item {
                id: newsSettings
                width: parent.width
                implicitHeight: newsSettingsColumn.height

                Column {
                    id: newsSettingsColumn
                    width: parent.width

                    property bool menuState: false
                    property var newsCheckboxes: new Array

                    Button {
                        id: newsSettingsTitle
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * newsSettingsTitle.padding
                            text: qsTr("News Channels")
                            font.pointSize: mainView.largeFontSize
                            font.weight: newsSettingsColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            newsSettingsColumn.menuState = !newsSettingsColumn.menuState
                            if (newsSettingsColumn.menuState) {
                                console.log("Settings | Will create new checkboxes")
                                newsSettingsColumn.createCheckboxes()
                            } else {
                                console.log("Settings | Will destroy new checkboxes")
                                newsSettingsColumn.destroyCheckboxes()
                            }
                        }
                    }

                    function createCheckboxes() {
                        var cannels = mainView.getFeeds()

                        for (var i = 0; i < cannels.length; i++) {
                            var component = Qt.createComponent("/Checkbox.qml", newsSettingsColumn)
                            var properties = { "actionId": cannels[i]["id"],
                                "text": cannels[i]["name"], "checked": cannels[i]["activated"],
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2}
                            var object = component.createObject(newsSettingsColumn, properties)
                            newsSettingsColumn.newsCheckboxes.push(object)
                        }
                        console.log("Settings News checkboxes created")
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < newsSettingsColumn.newsCheckboxes.length; i++) {
                            var checkbox = newsSettingsColumn.newsCheckboxes[i]
                            checkbox.destroy()
                        }
                        newsSettingsColumn.newsCheckboxes = new Array
                    }

                    function updateSettings(channelId, active) {
                        console.log("Settings | Update settings for " + channelId + ", " + active)
                        mainView.updateFeed(channelId, active, mainView.settingsAction.UPDATE)
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }
            }

            Item {
                id: shortcutSettings
                width: parent.width
                implicitHeight: shortcutSettingsColumn.height

                Column {
                    id: shortcutSettingsColumn
                    width: parent.width

                    property bool menuState: false
                    property var checkboxes: new Array

                    Button {
                        id: shortcutSettingsButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * shortcutSettingsButton.padding
                            text: qsTr("Shortcuts")
                            font.pointSize: mainView.largeFontSize
                            font.weight: shortcutSettingsColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            shortcutSettingsColumn.menuState = !shortcutSettingsColumn.menuState
                            if (shortcutSettingsColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                shortcutSettingsColumn.createCheckboxes()
                            } else {
                                console.log("Settings | Will destroy checkboxes")
                                shortcutSettingsColumn.destroyCheckboxes()
                            }
                        }
                    }

                    function createCheckboxes() {
                        var shortcuts = mainView.getActions()

                        for (var i = 0; i < shortcuts.length; i++) {
                            var component = Qt.createComponent("/Checkbox.qml", shortcutSettingsColumn)
                            var properties = { "actionId": shortcuts[i]["id"],
                                "text": shortcuts[i]["name"], "checked": shortcuts[i]["activated"],
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2 }
                            var object = component.createObject(shortcutSettingsColumn, properties)
                            shortcutSettingsColumn.checkboxes.push(object)
                        }
                        console.log("Settings | Checkboxes created")
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < shortcutSettingsColumn.checkboxes.length; i++) {
                            var checkbox = shortcutSettingsColumn.checkboxes[i]
                            checkbox.destroy()
                        }
                        shortcutSettingsColumn.checkboxes = new Array
                    }

                    function updateSettings(actionId, active) {
                        console.log("Settings | Update settings for " + channelId + ", " + active)
                        mainView.showToast(qsTr("Not yet supported"))

                        // Todo: implement
//                        mainView.updateAction(actionId, active)
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }
            }
        }
    }
}


