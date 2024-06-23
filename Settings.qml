import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN

LauncherPage {
    id: settingsPage
    anchors.fill: parent
    topPadding: mainView.innerSpacing

    function updateAvailablePlugins() {
        pluginSettingsItemColumn.loadAvailablePlugins()
    }

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: settingsColumn.height

        Column {
            id: settingsColumn
            width: parent.width

            function closeAllItemsExcept(item) {
                if (item !== newsSettingsItemColumn && newsSettingsItemColumn.newsCheckboxes.length > 0) {
                    newsSettingsItemColumn.menuState = false
                    newsSettingsItemColumn.destroyCheckboxes()
                }
                if (item !== sourceSettingsItemColumn && sourceSettingsItemColumn.checkboxes.length > 0) {
                    sourceSettingsItemColumn.menuState = false
                    sourceSettingsItemColumn.destroyCheckboxes()
                }
                if (item !== shortcutSettingsItemColumn && shortcutSettingsItemColumn.checkboxes.length > 0) {
                    shortcutSettingsItemColumn.menuState = false
                    shortcutSettingsItemColumn.destroyCheckboxes()
                }
                if (item !== searchSettingsItemColumn && searchSettingsItemColumn.checkboxes.length > 0) {
                    searchSettingsItemColumn.menuState = false
                    searchSettingsItemColumn.destroyCheckboxes()
                }
                if (item !== designSettingsItemColumn && designSettingsItemColumn.checkboxes.length > 0) {
                    designSettingsItemColumn.menuState = false
                    designSettingsItemColumn.destroyCheckboxes()
                }
                if (item !== pluginSettingsItemColumn && pluginSettingsItemColumn.checkboxes.length > 0) {
                    pluginSettingsItemColumn.menuState = false
                    pluginSettingsItemColumn.destroyCheckboxes()
                }
                if (item !== resetSettingsItemColumn && resetSettingsItemColumn.menuState) {
                    resetSettingsItemColumn.menuState = false
                }
            }

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
                id: themeSettingsItem
                width: parent.width
                implicitHeight: themeSettingsItemColumn.height
                preventStealing: true

                property var selectedMenuItem: themeSettingsItemTitle
                property bool menuState: false
                property double labelOpacity: 0.0

                Column {
                    id: themeSettingsItemColumn
                    width: parent.width

                    Label {
                        id: themeSettingsItemTitle

                        property var theme: themeSettings.theme

                        padding: mainView.innerSpacing
                        width: parent.width
                        text: qsTr("Dark Mode")
                        font.pointSize: mainView.largeFontSize
                        font.weight: themeSettingsItem.menuState ? Font.Black : Font.Normal
                        color: themeSettingsItem.menuState ? "white" : Universal.foreground
                        background: Rectangle {
                            anchors.fill: parent
                            color: themeSettingsItem.menuState === true ? mainView.accentColor : "transparent"
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
                    HighlightButton {
                        id: darkModeOption

                        property var theme: mainView.theme.Dark

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing
                        width: parent.width
                        visible: themeSettingsItem.menuState
                        text: qsTr("Dark Mode")
                        boldText: themeSettingsItem.selectedMenuItem === darkModeOption
                        textColor: "white"
                        textOpacity: themeSettingsItem.labelOpacity
                        backgroundColor: themeSettingsItem.menuState ? mainView.accentColor : "transparent"
                        fontPointSize: mainView.mediumFontSize
                    }
                    HighlightButton {
                        id: lightModeOption

                        property var theme: mainView.theme.Light

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing
                        width: parent.width
                        visible: themeSettingsItem.menuState
                        text: qsTr("Light Mode")
                        boldText: themeSettingsItem.selectedMenuItem === lightModeOption
                        textColor: "white"
                        textOpacity: themeSettingsItem.labelOpacity
                        backgroundColor: themeSettingsItem.menuState ? mainView.accentColor : "transparent"
                        fontPointSize: mainView.mediumFontSize
                    }
                    HighlightButton {
                        id: translucentModeOption

                        property var theme: mainView.theme.Translucent

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing * 2
                        width: parent.width
                        visible: themeSettingsItem.menuState
                        text: qsTr("Translucent Mode")
                        boldText: themeSettingsItem.selectedMenuItem === translucentModeOption
                        textColor: "white"
                        textOpacity: themeSettingsItem.labelOpacity
                        backgroundColor: themeSettingsItem.menuState ? mainView.accentColor : "transparent"
                        fontPointSize: mainView.mediumFontSize
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.
                        onRunningChanged: {
                            if (!running && themeSettingsItem.menuState) {
                                console.log("Settings | Switch on mode options labels")
                                themeSettingsItem.labelOpacity = 1.0
                            } else if (running && !themeSettingsItem.menuState) {
                                console.log("Settings | Switch off mode option labels")
                                themeSettingsItem.labelOpacity = 0.0
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
                    var selectedItem

                    if (mouseY > firstPoint.y && mouseY < firstPoint.y + darkModeOption.height) {
                        selectedItem = darkModeOption
                    } else if (mouseY > secondPoint.y && mouseY < secondPoint.y + lightModeOption.height) {
                        selectedItem = lightModeOption
                    } else if (mouseY > thirdPoint.y && mouseY < thirdPoint.y + translucentModeOption.height) {
                        selectedItem = translucentModeOption
                    } else {
                        selectedItem = themeSettingsItemTitle
                    }
                    if (selectedMenuItem !== selectedItem) {
                        selectedMenuItem = selectedItem
                        if (selectedMenuItem !== themeSettingsItemTitle && mainView.useVibration) {
                            AN.SystemDispatcher.dispatch("volla.launcher.vibrationAction", {"duration": mainView.vibrationDuration})
                        }
                    }
                }

                function executeSelection() {
                    console.log("Settings | Current mode: " + Universal.theme + ", " + themeSettings.theme)
                    console.log("Settings | Execute mode selection: " + selectedMenuItem.text + ", " + selectedMenuItem.theme)
                    if (themeSettings.theme !== selectedMenuItem.theme && selectedMenuItem !== themeSettingsItemTitle) {
                        themeSettingsItemTitle.text = selectedMenuItem.text

                        themeSettings.theme = selectedMenuItem.theme

                        if (themeSettings.sync) {
                            themeSettings.sync()
                        }

                        switch (themeSettings.theme) {
                            case mainView.theme.Dark:
                                console.log("Setting | Enable dark mode")
                                mainView.switchTheme(mainView.theme.Dark, true)
                                break
                            case mainView.theme.Light:
                                console.log("Setting | Enable light mode")
                                mainView.switchTheme(mainView.theme.Light, true)
                                break
                            case mainView.theme.Translucent:
                                console.log("Setting | Enable translucent mode")
                                mainView.switchTheme(mainView.theme.Translucent, true)
                                break
                            default:
                                console.log("Settings | Unknown theme selected: " + themeSettings.theme)
                        }

                        selectedMenuItem = themeSettingsItemTitle
                    }
                }

                Settings {
                    id: themeSettings
                    property int theme: mainView.theme.Dark
                }
            }

            MouseArea {
                id: securitySettingsItem
                width: parent.width
                implicitHeight: securitySettingsItemColumn.height
                preventStealing: true

                property var selectedMenuItem: securitySettingsItemTitle
                property bool menuState: false
                property double labelOpacity: 0.0

                Column {
                    id: securitySettingsItemColumn
                    width: parent.width

                    Button {
                        id: securitySettingsItemTitle

                        property var isActiveSecurityMode: false

                        enabled: false
                        padding: mainView.innerSpacing
                        width: parent.width
                        text: qsTr("Security mode is OFF")
                        contentItem: Row {
                            Text {
                                text: securitySettingsItemTitle.text
                                width: parent.width - securitySettingsItemTitleIcon.width - mainView.innerSpacing
                                font.pointSize: mainView.largeFontSize
                                font.weight: securitySettingsItem.menuState ? Font.Black : Font.Normal
                                color: securitySettingsItem.menuState ? "white" : Universal.foreground
                            }
                            Image {
                                id: securitySettingsItemTitleIcon
                                source: Qt.resolvedUrl("icons/lock@2x.png")
                                visible: false

                                ColorOverlay {
                                    anchors.fill: securitySettingsItemTitleIcon
                                    source: securitySettingsItemTitleIcon
                                    color: mainView.fontColor
                                }
                            }
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: securitySettingsItem.menuState === true ? mainView.accentColor : "transparent"
                        }

                        onTextChanged: {
                            securitySettingsItemTitleIcon.visible = text === securityModeOnOption.text
                        }
                    }
                    Button {
                        id: securityModeOffOption

                        property var isActiveSecurityMode: false

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing
                        width: parent.width
                        visible: securitySettingsItem.menuState
                        text: qsTr("Security mode is OFF")
                        contentItem: Text {
                            text: securityModeOffOption.text
                            font.pointSize: mainView.mediumFontSize
                            font.weight: securitySettingsItem.selectedMenuItem === securityModeOffOption ? Font.Black : Font.Normal
                            color: "white"
                            opacity: securitySettingsItem.labelOpacity
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: securitySettingsItem.menuState ? mainView.accentColor : "transparent"
                        }
                    }
                    Button {
                        id: securityModeOnOption

                        property var isActiveSecurityMode: true

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing
                        width: parent.width
                        visible: securitySettingsItem.menuState
                        text: qsTr("Security mode is ON")
                        contentItem: Row {
                            Text {
                                text: securityModeOnOption.text
                                width: parent.width - securityModeOnOptionIcon.width - mainView.innerSpacing
                                font.pointSize: mainView.mediumFontSize
                                font.weight: securitySettingsItem.selectedMenuItem === securityModeOnOption ? Font.Black : Font.Normal
                                color: "white"
                                opacity: securitySettingsItem.labelOpacity
                            }
                            Image {
                                id: securityModeOnOptionIcon
                                source: Qt.resolvedUrl("icons/lock@2x.png")
                            }
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: securitySettingsItem.menuState ? mainView.accentColor : "transparent"
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.
                        onRunningChanged: {
                            if (!running && securitySettingsItem.menuState) {
                                console.log("Settings | Switch on security options labels")
                                securitySettingsItem.labelOpacity = 1.0
                            } else if (running && !securitySettingsItem.menuState) {
                                console.log("Settings | Switch off security option labels")
                                securitySettingsItem.labelOpacity = 0.0
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
                    var firstPoint = mapFromItem(securityModeOffOption, 0, 0)
                    var secondPoint = mapFromItem(securityModeOnOption, 0, 0)
                    var selectedItem

                    if (mouseY > firstPoint.y && mouseY < firstPoint.y + securityModeOffOption.height) {
                        selectedItem = securityModeOffOption
                    } else if (mouseY > secondPoint.y && mouseY < secondPoint.y + securityModeOnOption.height) {
                        selectedItem = securityModeOnOption
                    } else {
                        selectedItem = securitySettingsItemTitle
                    }
                    if (selectedMenuItem !== selectedItem) {
                        selectedMenuItem = selectedItem
                        if (selectedMenuItem !== securitySettingsItemTitle && mainView.useVibration) {
                            AN.SystemDispatcher.dispatch("volla.launcher.vibrationAction", {"duration": mainView.vibrationDuration})
                        }
                    }
                }

                function executeSelection() {
                    console.log("Settings | Execute mode selection: " + selectedMenuItem.text)
                    if (securitySettingsItemTitle.text !== selectedMenuItem.text) {
                        if (selectedMenuItem.text === securityModeOnOption.text) {
                            // Check, if password is set
                            AN.SystemDispatcher.dispatch("volla.launcher.checkSecurityPasswordAction", {})
                        } else if (selectedMenuItem.text === securityModeOffOption.text) {
                            passwordDialog.backgroundColor = mainView.fontColor.toString() === "white" || mainView.fontColor.toString() === "#ffffff"
                                    ? "#292929" : "#CCCCCC"
                            passwordDialog.definePasswordMode = false
                            passwordDialog.isPasswordSet = true
                            passwordDialog.open()
                        }
                    }
                }

                Dialog {
                    id: passwordDialog

                    anchors.centerIn: parent
                    width: parent.width - mainView.innerSpacing * 4
                    modal: true
                    dim: false

                    property var backgroundColor: "#292929"
                    property bool definePasswordMode: false
                    property bool isPasswordSet: false

                    onOpened: {
                        passwordField.text = ""
                        confirmationField.text = ""
                        height: dialogTitle.height + passwordField.height +
                                dialogLabel.height + confirmationField.height +
                                keepPasswordCheckBox.height + okButton.height +
                                mainView.innerSpacing * 2
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: passwordDialog.backgroundColor
                        border.color: "transparent"
                        radius: mainView.innerSpacing / 2
                    }

                    enter: Transition {
                         NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
                    }

                    exit: Transition {
                        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
                    }

                    contentItem: Column {
                        id: dialogColumn

                        Label {
                            id: dialogTitle
                            text: qsTr("Enter password")
                            color: mainView.fontColor
                            font.pointSize: mainView.mediumFontSize
                            bottomPadding: mainView.innerSpacing
                            background: Rectangle {
                                color: "transparent"
                                border.color: "transparent"
                            }
                        }

                        TextField {
                            id: passwordField
                            echoMode: TextField.Password
                            width: parent.width
                            color: mainView.fontColor
                            placeholderTextColor: "darkgrey"
                            font.pointSize: mainView.mediumFontSize
                            background: Rectangle {
                                color: mainView.fontColor.toString() === "white" || mainView.fontColor.toString() === "#ffffff"
                                       ? "black" : "white"
                                border.color: "transparent"
                            }
                        }

                        Label {
                            id: dialogLabel
                            text: qsTr("Repeat password")
                            color: mainView.fontColor
                            topPadding: mainView.innerSpacing
                            bottomPadding: mainView.innerSpacing
                            font.pointSize: mainView.mediumFontSize
                            visible: passwordDialog.definePasswordMode
                            background: Rectangle {
                                color: "transparent"
                                border.color: "transparent"
                            }
                        }

                        TextField {
                            id: confirmationField
                            echoMode: TextField.Password
                            width: parent.width
                            color: mainView.fontColor
                            placeholderTextColor: "darkgrey"
                            font.pointSize: mainView.mediumFontSize
                            visible: passwordDialog.definePasswordMode
                            background: Rectangle {
                                color: mainView.fontColor.toString() === "white" || mainView.fontColor.toString() === "#ffffff"
                                       ? "black" : "white"
                                border.color: "transparent"
                            }
                        }

                        CheckBox {
                            id: keepPasswordCheckBox
                            width: parent.width
                            topPadding: mainView.innerSpacing
                            text: qsTr("Keep existing Password")
                            checked: passwordDialog.isPasswordSet
                            visible: passwordDialog.definePasswordMode
                            contentItem: Text {
                                text: keepPasswordCheckBox.text
                                wrapMode: Text.WordWrap
                                width: parent.width - leftPadding
                                leftPadding: 2 * mainView.innerSpacing
                                color: mainView.fontColor
                                font.pointSize: mainView.mediumFontSize
                            }
                        }

                        Row {
                            width: parent.width
                            topPadding: mainView.innerSpacing
                            spacing: mainView.innerSpacing

                            Button {
                                id: cancelButton
                                flat: true
                                padding: mainView.innerSpacing / 2
                                width: parent.width / 2 - mainView.innerSpacing / 2
                                text: qsTr("Cancel")

                                contentItem: Text {
                                    text: cancelButton.text
                                    color: mainView.fontColor
                                    font.pointSize: mainView.mediumFontSize
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "gray"
                                }

                                onClicked: {
                                    securitySettingsItem.selectedMenuItem = securitySettingsItemTitle
                                    passwordDialog.close()
                                }
                            }

                            Button {
                                id: okButton
                                width: parent.width / 2 - mainView.innerSpacing / 2
                                padding: mainView.innerSpacing / 2
                                flat: true
                                text: qsTr("Ok")

                                contentItem: Text {
                                    text: okButton.text
                                    color: mainView.fontColor
                                    font.pointSize: mainView.mediumFontSize
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "gray"
                                }

                                onClicked: {
                                    if (passwordDialog.definePasswordMode && !keepPasswordCheckBox.checked
                                            && passwordField.text !== confirmationField.text) {
                                        mainView.showToast(qsTr("Wrong password confirmation"))
                                    } else if (passwordDialog.definePasswordMode && !keepPasswordCheckBox.checked
                                               && passwordField.text.length < 5) {
                                        mainView.showToast(qsTr("Password needs at least four characters or numbers"))
                                    } else {
                                        AN.SystemDispatcher.dispatch(
                                                    "volla.launcher.securityModeAction",
                                                    {"password": passwordField.text,
                                                     "keepPassword": keepPasswordCheckBox.checked,
                                                     "activate": securitySettingsItem.selectedMenuItem === securityModeOnOption})
                                        passwordDialog.close()
                                    }
                                }
                            }
                        }
                    }
                }

                Connections {
                    target: AN.SystemDispatcher

                    onDispatched: {
                        if (type === "volla.launcher.securityModeResponse") {
                            if (message["succeeded"]) {
                                securitySettingsItemTitle.text = securitySettingsItem.selectedMenuItem.text
                                securitySettingsItemTitle.isActiveSecurityMode = securitySettingsItem.selectedMenuItem.isActiveSecurityMode
                                securitySettingsItem.selectedMenuItem = securitySettingsItemTitle
                                AN.SystemDispatcher.dispatch("volla.launcher.appCountAction", {})
                            } else {
                                securitySettingsItem.selectedMenuItem = securitySettingsItemTitle
                                mainView.showToast(qsTr("Wrong password"))
                            }
                        } else if (type === "volla.launcher.securityStateResponse") {
                            console.log("Settings | Security state: " + message["isActive"] + ", " + message["error"])
                            securitySettingsItemTitle.text = message["isActive"]  ? securityModeOnOption.text
                                                                                  : securityModeOffOption.text
                            securitySettingsItem.visible = message["error"] === undefined && message["isInstalled"] && message["isAvailable"]
                        } else if (type === "volla.launcher.checkSecurityPasswordResponse") {
                            console.log("Settings | Password is set: " + message["isPasswordSet"])
                            passwordDialog.backgroundColor = mainView.fontColor.toString() === "white" || mainView.fontColor.toString() === "#ffffff"
                                    ? "#292929" : "#CCCCCC"
                            passwordDialog.definePasswordMode = true
                            passwordDialog.isPasswordSet = message["isPasswordSet"]
                            passwordDialog.open()
                        }
                    }
                }
            }

            Item {
                id: newsSettingsItem
                width: parent.width
                implicitHeight: newsSettingsItemColumn.height

                Column {
                    id: newsSettingsItemColumn
                    width: parent.width

                    property bool menuState: false
                    property var newsCheckboxes: new Array

                    HighlightButton {
                        id: newsSettingsItemTitle
                        width: parent.width
                        padding: mainView.innerSpacing
                        text: qsTr("News Channels")
                        boldText: newsSettingsItemColumn.menuState
                        onClicked: {
                            newsSettingsItemColumn.menuState = !newsSettingsItemColumn.menuState
                            if (newsSettingsItemColumn.menuState) {
                                console.log("Settings | Will create new checkboxes")
                                newsSettingsItemColumn.createCheckboxes()
                                settingsColumn.closeAllItemsExcept(newsSettingsItemColumn)
                            } else {
                                console.log("Settings | Will destroy new checkboxes")
                                newsSettingsItemColumn.destroyCheckboxes()
                            }
                        }
                    }

                    function createCheckboxes() {
                        var cannels = mainView.getFeeds()

                        for (var i = 0; i < cannels.length; i++) {
                            var component = Qt.createComponent("/Checkbox.qml", newsSettingsItemColumn)
                            var properties = { "actionId": cannels[i]["id"],
                                "text": cannels[i]["name"], "activeCheckbox": false, "checked": cannels[i]["activated"],
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                "hasRemoveButton": true, "accentColor": mainView.accentColor }
                            var object = component.createObject(newsSettingsItemColumn, properties)
                            object.activeCheckbox = true
                            newsSettingsItemColumn.newsCheckboxes.push(object)
                        }
                        console.log("Settings News checkboxes created")
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < newsSettingsItemColumn.newsCheckboxes.length; i++) {
                            var checkbox = newsSettingsItemColumn.newsCheckboxes[i]
                            checkbox.destroy()
                        }
                        newsSettingsItemColumn.newsCheckboxes = new Array
                    }

                    function updateSettings(channelId, active) {
                        console.log("Settings | Update settings for " + channelId + ", " + active)
                        mainView.updateFeed(channelId, active, mainView.settingsAction.UPDATE)
                    }

                    function removeSettings(channelId) {
                        console.log("Settings | Remove settings for " + channelId)
                        mainView.updateFeed(channelId, false, mainView.settingsAction.REMOVE)
                        for (var i = 0; i < newsSettingsItemColumn.newsCheckboxes.length; i++) {
                            var checkbox = newsSettingsItemColumn.newsCheckboxes[i]
                            if (checkbox.actionId === channelId) {
                                newsCheckboxes.splice(i, 1)
                                checkbox.destroy()
                            }
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }
            }

            Item {
                id: shortcutSettingsItem
                width: parent.width
                implicitHeight: shortcutSettingsItemColumn.height

                Column {
                    id: shortcutSettingsItemColumn
                    width: parent.width

                    property bool menuState: false
                    property var checkboxes: new Array

                    HighlightButton {
                        id: shortcutSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        text: qsTr("Shortcuts")
                        boldText: shortcutSettingsItemColumn.menuState
                        onClicked: {
                            shortcutSettingsItemColumn.menuState = !shortcutSettingsItemColumn.menuState
                            if (shortcutSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                shortcutSettingsItemColumn.createCheckboxes()
                                settingsColumn.closeAllItemsExcept(shortcutSettingsItemColumn)
                            } else {
                                console.log("Settings | Will destroy checkboxes")
                                shortcutSettingsItemColumn.destroyCheckboxes()
                            }
                        }
                    }

                    function createCheckboxes() {
                        var shortcuts = mainView.getActions()

                        for (var i = 0; i < shortcuts.length; i++) {
                            var component = Qt.createComponent("/Checkbox.qml", shortcutSettingsItemColumn)
                            var properties = { "actionId": shortcuts[i]["id"],
                                "text": shortcuts[i]["name"], "checked": shortcuts[i]["activated"],
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                "hasRemoveButton": getFilteredShortcuts(mainView.defaultActions, "id", shortcuts[i]["id"]).length === 0,
                                "accentColor": mainView.accentColor }
                            var object = component.createObject(shortcutSettingsItemColumn, properties)
                            object.activeCheckbox = true
                            shortcutSettingsItemColumn.checkboxes.push(object)
                        }
                        addButton.visible = true
                        console.log("Settings | Checkboxes created")
                    }

                    function addCheckbox(actionId, label) {
                        var component = Qt.createComponent("/Checkbox.qml", shortcutSettingsItemColumn)
                        var properties = { "actionId": actionId, "text": label, "checked": true,
                            "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                            "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                            "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                            "hasRemoveButton": true, "accentColor": mainView.accentColor }
                        var object = component.createObject(shortcutSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        shortcutSettingsItemColumn.checkboxes.push(object)
                    }

                    function getFilteredShortcuts(array, key, value) {
                        return array.filter(function(e) {
                            return e[key] === value;
                        });
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < shortcutSettingsItemColumn.checkboxes.length; i++) {
                            var checkbox = shortcutSettingsItemColumn.checkboxes[i]
                            checkbox.destroy()
                        }
                        addButton.visible = false
                        shortcutSettingsItemColumn.checkboxes = new Array
                    }

                    function updateSettings(actionId, active) {
                        console.log("Settings | Update settings for " + actionId + ", " + active)
                        mainView.updateAction(actionId, active, mainView.settingsAction.UPDATE)
                    }

                    function removeSettings(actionId) {
                        console.log("Settings | Remove settings for " + actionId)
                        mainView.updateAction(actionId, false, mainView.settingsAction.REMOVE)
                        for (var i = 0; i < shortcutSettingsItemColumn.checkboxes.length; i++) {
                            var checkbox = shortcutSettingsItemColumn.checkboxes[i]
                            if (checkbox.actionId === actionId) {
                                checkboxes.splice(i, 1)
                                checkbox.destroy()
                            }
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }
            }

            Button {
                id: addButton
                leftPadding: mainView.innerSpacing + 6.0
                rightPadding: mainView.innerSpacing
                bottomPadding: mainView.innerSpacing / 2
                flat: true
                text: "+"
                font.pointSize: mainView.largeFontSize
                visible: false

                onClicked: {
                    appMenuModel.setData(mainView.getApps())
                    appMenu.popup(settingsPage)
                }

                Menu {
                    id: appMenu

                    property double fontSize: mainView.largeFontSoze / 72 * Screen.pixelDensity * 25.4

                    background: Rectangle {
                        implicitHeight:  contentItem.height
                        implicitWidth: 200
                        color: mainView.accentColor
                        radius: mainView.innerSpacing
                    }

                    contentItem: ListView {
                        id: appList
                        delegate: Button {
                            width: parent.width
                            leftPadding: mainView.innerSpacing
                            rightPadding: mainView.innerSpacing
                            topPadding: mainView.innerSpacing
                            bottomPadding: index === appMenuModel.count - 1 ? mainView.innerSpacing : 0
                            flat: true
                            contentItem: Text {
                                text: model.label
                                color: mainView.fontColor
                                font.pointSize: mainView.mediumFontSize
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                            }
                            onClicked: {
                                console.log("Settings | App " + model["label"] + " selected for shortcuts");
                                mainView.updateAction(
                                            model["package"], true, mainView.settingsAction.CREATE,
                                            {"id": model["package"], "name": qsTr("Open") + " " + model["label"], "activated": true} )
                                appMenuModel.append(
                                            {"id": model["package"], "name": qsTr("Open") + " " + model["label"], "activated": true} )

                                var component = Qt.createComponent("/Checkbox.qml", shortcutSettingsItemColumn)
                                var properties = { "actionId": model["package"],
                                    "text": qsTr("Open") + " " + model["label"], "checked": true,
                                    "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                    "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                    "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                    "hasRemoveButton": true, "accentColor": mainView.accentColor }
                                var object = component.createObject(shortcutSettingsItemColumn, properties)
                                shortcutSettingsItemColumn.checkboxes.push(object)
                                appMenu.close()
                            }
                        }
                        model: appMenuModel
                    }
                }

                ListModel {
                    id: appMenuModel
                    function setData(data) {
                        console.log("Settings | Menu size is " + data.length)
                        clear()
                        for (var i = 0; i < data.length; i++) {
                            append(data[i])
                        }
                    }
                }
            }

            Item {
                id: sourceSettingsItem
                width: parent.width
                implicitHeight: sourceSettingsItemColumn.height
                visible: true

                Column {
                    id: sourceSettingsItemColumn
                    width: parent.width

                    property bool menuState: false
                    property var checkboxes: new Array

                    HighlightButton {
                        id: sourceSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        boldText: sourceSettingsItemColumn.menuState
                        text: qsTr("Source settings")
                        onClicked: {
                            sourceSettingsItemColumn.menuState = !sourceSettingsItemColumn.menuState
                            if (sourceSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                sourceSettingsItemColumn.createCheckboxes()
                                settingsColumn.closeAllItemsExcept(sourceSettingsItemColumn)
                            } else {
                                console.log("Settings | Will destroy checkboxes")
                                sourceSettingsItemColumn.destroyCheckboxes()
                            }
                        }
                    }

                    function createCheckboxes() {
                        var component = Qt.createComponent("/Checkbox.qml", sourceSettingsItemColumn)
                        var properties = { "actionId": "signal",
                                "text": qsTr("Signal"), "checked": sourceSettings.signalIsActivated,
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                "accentColor": mainView.accentColor}
                        var object = component.createObject(sourceSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        sourceSettingsItemColumn.checkboxes.push(object)
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < sourceSettingsItemColumn.checkboxes.length; i++) {
                            var checkbox = sourceSettingsItemColumn.checkboxes[i]
                            checkbox.destroy()
                        }
                        sourceSettingsItemColumn.checkboxes = new Array
                    }

                    function updateSettings(actionId, active) {
                        console.log("Settings | Update settings for " + actionId + ", " + active)

                        if (actionId === "signal") {
                            AN.SystemDispatcher.dispatch("volla.launcher.signalEnable", { "enableSignal": active})
                            mainView.updateSettings("activateSignal", active)
                            sourceSettings.signalIsActivated = active
                            mainView.isActiveSignal = active
                        }
                    }

                    Settings {
                        id: sourceSettings

                        property bool signalIsActivated: false
                    }

                    Connections {
                        target: AN.SystemDispatcher

                        onDispatched: {
                            if (type === "volla.launcher.signalAppNotInstalled") {
                                mainView.showToast(qsTr("Signal app is not installed"))
                                for (var i = 0; i < sourceSettingsItemColumn.checkboxes.length; i++) {
                                    var checkbox = sourceSettingsItemColumn.checkboxes[i]
                                    if (checkbox.actionId === "signal") checkbox.checked = false
                                }
                            }
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }          
            }

            Item {
                id: searchSettingsItem
                width: parent.width
                implicitHeight: searchSettingsItemColumn.height
                visible: true

                Column {
                    id: searchSettingsItemColumn
                    width: parent.width

                    property bool menuState: false
                    property var checkboxes: new Array

                    HighlightButton {
                        id: searchSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        text: qsTr("Search engines")
                        boldText: searchSettingsItemColumn.menuState
                        onClicked: {
                            searchSettingsItemColumn.menuState = !searchSettingsItemColumn.menuState
                            if (searchSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                searchSettingsItemColumn.createCheckboxes()
                                settingsColumn.closeAllItemsExcept(searchSettingsItemColumn)
                            } else {
                                console.log("Settings | Will destroy checkboxes")
                                searchSettingsItemColumn.destroyCheckboxes()
                            }
                        }
                    }

                    function createCheckboxes() {
                        var component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        var properties = { "actionId": "duckduckgo",
                                "text": qsTr("DuckDuckGo"), "checked": mainView.getSearchMode() === mainView.searchMode.Duck,
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2, "isToggle": true,
                                "accentColor": mainView.accentColor }
                        var object = component.createObject(searchSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        searchSettingsItemColumn.checkboxes.push(object)

                        component = Qt.createComponent("/Checkbox.qml", searchSettingsItemColumn)
                        properties["actionId"] = "startpage"
                        properties["text"] = qsTr("Startpage")
                        properties["checked"] = mainView.getSearchMode() === mainView.searchMode.StartPage
                        properties["accentColor"] = mainView.accentColor
                        object = component.createObject(searchSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        searchSettingsItemColumn.checkboxes.push(object)

                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "metager"
                        properties["text"] = qsTr("MetaGer")
                        properties["checked"] = mainView.getSearchMode() === mainView.searchMode.MetaGer
                        properties["accentColor"] = mainView.accentColor
                        object = component.createObject(searchSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        searchSettingsItemColumn.checkboxes.push(object)
                        console.log("Settings | Checkboxes created")
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < searchSettingsItemColumn.checkboxes.length; i++) {
                            var checkbox = searchSettingsItemColumn.checkboxes[i]
                            checkbox.destroy()
                        }
                        searchSettingsItemColumn.checkboxes = new Array
                    }

                    function updateSettings(actionId, active) {
                        console.log("Settings | Update settings for " + actionId + ", " + active)

                        for (var i = 0; i < searchSettingsItemColumn.checkboxes.length; i++) {
                            var checkbox = searchSettingsItemColumn.checkboxes[i]
                            checkbox.activeCheckbox = false
                            checkbox.checked = checkbox.actionId === actionId && active ? active : !active
                            checkbox.activeCheckbox = true
                        }

                        if (actionId === "duckduckgo" && active) {
                            mainView.updateSearchMode(mainView.searchMode.Duck)
                        } else if (actionId === "startpage" && active) {
                            mainView.updateSearchMode(mainView.searchMode.StartPage)
                        } else if (actionId === "metager" && active) {
                            mainView.updateSearchMode(mainView.searchMode.MetaGer)
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }
            }

            Item {
                id: designSettingsItem
                width: parent.width
                implicitHeight: designSettingsItemColumn.height

                Column {
                    id: designSettingsItemColumn
                    width: parent.width

                    property bool menuState: false
                    property var checkboxes: new Array

                    HighlightButton {
                        id: designSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        text: qsTr("Display and menus")
                        boldText: designSettingsItemColumn.menuState
                        onClicked: {
                            designSettingsItemColumn.menuState = !designSettingsItemColumn.menuState
                            if (designSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                designSettingsItemColumn.createCheckboxes()
                                settingsColumn.closeAllItemsExcept(designSettingsItemColumn)
                            } else {
                                console.log("Settings | Will destroy checkboxes")
                                designSettingsItemColumn.destroyCheckboxes()
                            }
                        }
                    }

                    function createCheckboxes() {
                        var component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        var properties = { "actionId": "fullscreen",
                                "text": qsTr("Fullscreen"), "checked": designSettings.fullscreen,
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                "accentColor": mainView.accentColor }
                        var object = component.createObject(designSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        designSettingsItemColumn.checkboxes.push(object)

                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "coloredIcons"
                        properties["text"] = qsTr("Use colored app icons")
                        properties["checked"] = designSettings.useColoredIcons
                        properties["accentColor"] = mainView.accentColor
                        object = component.createObject(designSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        designSettingsItemColumn.checkboxes.push(object)

                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "startupIndex"
                        properties["text"] = qsTr("Show apps at startup")
                        properties["checked"] = designSettings.showAppsAtStartup
                        properties["accentColor"] = mainView.accentColor
                        object = component.createObject(designSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        designSettingsItemColumn.checkboxes.push(object)

                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "hapticMenus"
                        properties["text"] = qsTr("Use haptic menus")
                        properties["checked"] = designSettings.useHapticMenus
                        properties["accentColor"] = mainView.accentColor
                        object = component.createObject(designSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        designSettingsItemColumn.checkboxes.push(object)

                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "useGroupedApps"
                        properties["text"] = qsTr("Show grouped apps")
                        properties["checked"] = designSettings.useGroupedApps
                        properties["accentColor"] = mainView.accentColor
                        object = component.createObject(designSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        designSettingsItemColumn.checkboxes.push(object)

                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "useCategories"
                        properties["text"] = qsTr("Use app categories")
                        properties["checked"] = designSettings.useCategories
                        properties["accentColor"] = mainView.accentColor
                        object = component.createObject(designSettingsItemColumn, properties)
                        object.activeCheckbox = true
                        designSettingsItemColumn.checkboxes.push(object)

                        console.log("Settings | Checkboxes created")
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < designSettingsItemColumn.checkboxes.length; i++) {
                            var checkbox = designSettingsItemColumn.checkboxes[i]
                            checkbox.destroy()
                        }
                        designSettingsItemColumn.checkboxes = new Array
                    }

                    function updateSettings(actionId, active) {
                        console.log("Settings | Update settings for " + actionId + ", " + active)

                        if (actionId === "fullscreen") {
                            designSettings.fullscreen = active
                            designSettings.sync()
                            mainView.updateSettings("fullscreen", active)
                        } else if (actionId === "coloredIcons") {
                            designSettings.useColoredIcons = active
                            designSettings.sync()
                            mainView.updateGridView("coloredIcons", active)
                        } else if (actionId === "startupIndex") {
                            designSettings.showAppsAtStartup = active
                            designSettings.sync()
                            mainView.updateSettings("showAppsAtStartup", active)
                        } else if (actionId === "hapticMenus") {
                            designSettings.useHapticMenus = active
                            designSettings.sync()
                            mainView.updateSettings("useHapticMenus", active)
                        } else if (actionId === "useGroupedApps") {
                            designSettings.useGroupedApps = active
                            designSettings.sync()
                            mainView.updateGridView("useGroupedApps", active)
                        } else if (actionId === "useCategories") {
                            designSettings.useCategories = active
                            designSettings.sync()
                            mainView.updateGridView("useCategories", active)
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0

                        onRunningChanged: {
                            console.log("Settings | Running changed to " + running)
                            if (!running) {
                                blurLabel.visible = designSettingsItemColumn.menuState
                                blurSlider.visible = designSettingsItemColumn.menuState
                            }
                        }
                    }
                }

                Settings {
                    id: designSettings
                    property bool fullscreen: false
                    property bool useColoredIcons: false
                    property bool useGroupedApps: true
                    property bool useCategories: false
                    property bool showAppsAtStartup: false
                    property bool useHapticMenus: true
                    property double blurEffect: 30
                }
            }

            Label {
                id: blurLabel
                topPadding: mainView.innerSpacing
                leftPadding: mainView.innerSpacing
                rightPadding: mainView.innerSpacing
                text: qsTr("Background blur")
                font.pointSize: mainView.mediumFontSize
                visible: false
            }

            Slider {
                id: blurSlider
                topPadding: mainView.innerSpacing
                leftPadding: mainView.innerSpacing
                rightPadding: mainView.innerSpacing
                width: parent.width
                from: 0
                to: 100
                value: designSettings.blurEffect
                visible: false

                handle: Rectangle {
                    x: blurSlider.leftPadding + blurSlider.visualPosition * (blurSlider.availableWidth - width)
                    y: blurSlider.topPadding + blurSlider.availableHeight / 2 - height / 2
                    implicitWidth: mainView.largeFontSize
                    implicitHeight: mainView.largeFontSize
                    radius: mainView.largeFontSize / 2
                    color: mainView.accentColor
                    border.color: mainView.accentColor
                }

                onValueChanged: {
                    console.log("Settings | Blurr filter chanded to " + value)
                    designSettings.blurEffect = value
                    mainView.updateSettings("blurEffect", value)
                }
            }

            Item {
                id: pluginSettingsItem
                width: parent.width
                implicitHeight: pluginSettingsItemColumn.height
                visible: true

                Column {
                    id: pluginSettingsItemColumn
                    width: parent.width

                    property bool menuState: false
                    property var checkboxes: new Array
                    property var availablePlugins: new Array
                    property var dpluginListUrl: "https://raw.githubusercontent.com/HelloVolla/android-launcher-plugin/dev/VollaPluginList.json"
                    property var pluginListUrl: "https://raw.githubusercontent.com/HelloVolla/android-launcher-plugin/master/VollaPluginList.json"

                    Button {
                        id: pluginSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * pluginSettingsItemButton.padding
                            text: qsTr("Springboard Skills")
                            font.pointSize: mainView.largeFontSize
                            font.weight: pluginSettingsItemColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            pluginSettingsItemColumn.menuState = !pluginSettingsItemColumn.menuState
                            if (pluginSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                pluginSettingsItemColumn.createCheckboxes()
                                settingsColumn.closeAllItemsExcept(pluginSettingsItemColumn)
                            } else {
                                console.log("Settings | Will destroy checkboxes")
                                pluginSettingsItemColumn.destroyCheckboxes()
                            }
                        }
                     }

                    function loadAvailablePlugins() {
                        console.log("Settings | Load plugins")
                        availablePlugins = new Array
                        var xhr = new XMLHttpRequest();
                        var temp;
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                console.log("Settings | got plugins request responce")
                                if (xhr.status === 200) {
                                    console.log("Settings | plugin responste status 200")
                                    var jsonData = JSON.parse(xhr.responseText)
                                    console.log("Settings | jsonData " + jsonData["pluginList"])
                                    availablePlugins = jsonData["pluginList"]
                                    var installedPlugins = mainView.getInstalledPlugins()
                                    var installedPluginIds = new Array
                                    for (var i = 0; i < availablePlugins.length; i++) {
                                        availablePlugins[i].isEnabled = installedPlugins.some(plugin => plugin.id === availablePlugins[i].id)
                                        var installedPlugin = installedPlugins.find(plugin => plugin.id === availablePlugins[i].id)
                                        if (installedPlugin !== undefined && installedPlugin.version < availablePlugins[i].version) {
                                            mainView.updateInstalledPlugins(pluginMetadata, true, function(success) {
                                                if (!success) {
                                                    console.log("Settings | Successfully updated plugin " + availablePlugins[i].id)
                                                }
                                            })
                                        }
                                    }
                                } else {
                                    mainView.showToast(qsTr("Couldn't load available plugins"))
                                    console.error("Settings | Error retrieving available plugins:", xhr.status, xhr.statusText)
                                    availablePlugins = mainView.getInstalledPlugins()
                                    for (i = 0; i < availablePlugins.length; i++) {
                                        availablePlugins[i].isEnabled = true
                                    }
                                }
                            }
                        };
                        xhr.open("GET", pluginListUrl);
                        console.log("Settings | Sending available plugins request");
                        xhr.send();
                    }

                    function createCheckboxes() {
                        for (var i = 0; i < pluginSettingsItemColumn.availablePlugins.length; i++) {
                            var component = Qt.createComponent("/Checkbox.qml", pluginSettingsItemColumn)
                            var properties = { "actionId": availablePlugins[i]["id"],
                                "text": availablePlugins[i]["name"], "checked": availablePlugins[i]["isEnabled"],
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                "hasDescriptionButton": true, "accentColor": mainView.accentColor }
                            var object = component.createObject(pluginSettingsItemColumn, properties)
                            object.activeCheckbox = true
                            pluginSettingsItemColumn.checkboxes.push(object)
                        }
                        console.log("Settings | Checkboxes created")
                    }

                    function destroyCheckboxes() {
                        for (var i = 0; i < pluginSettingsItemColumn.checkboxes.length; i++) {
                            var checkbox = pluginSettingsItemColumn.checkboxes[i]
                            checkbox.destroy()
                        }
                        pluginSettingsItemColumn.checkboxes = new Array
                    }

                    function showDescription(actionId) {
                        pluginDialog.backgroundColor = mainView.fontColor.toString() === "#ffffff"  ? "#292929" : "#CCCCCC"
                        for (var i = 0; i < pluginSettingsItemColumn.availablePlugins.length; i++) {
                            if (pluginSettingsItemColumn.availablePlugins[i].id === actionId) {
                                pluginDialog.dialogDescritpion = pluginSettingsItemColumn.availablePlugins[i].description
                            }
                        }
                        pluginDialog.open()
                    }

                    function updateSettings(actionId, active) {
                        console.log("Settings | Update plugin settings for " + actionId + ", " + active)
                        var pluginMetadata = availablePlugins.find(p => p.id === actionId)
                        pluginMetadata.isEnabled = active
                        mainView.updateInstalledPlugins(pluginMetadata, active, function(success) {
                            if (!success) {
                                for (var i = 0; i < pluginSettingsItemColumn.checkboxes.length; i++) {
                                    var checkbox = pluginSettingsItemColumn.checkboxes[i]
                                    if (checkbox.actionId === actionId) checkbox.checked = false
                                }
                            }
                        })
                    }
                }

                Dialog {
                    id: pluginDialog

                    anchors.centerIn: parent
                    width: parent.width - mainView.innerSpacing * 4
                    modal: true
                    dim: false

                    property var backgroundColor: "#292929"
                    property var dialogDescritpion: ""

                    background: Rectangle {
                        anchors.fill: parent
                        color: pluginDialog.backgroundColor
                        border.color: "transparent"
                        radius: mainView.innerSpacing / 2
                    }

                    contentItem: Column {
                        spacing: mainView.innerSpacing / 2

                        Label {
                            id: pluginDialogTitle
                            width: parent.width
                            padding: mainView.innerSpacing / 2
                            text: pluginDialog.dialogDescritpion
                            color: mainView.fontColor
                            wrapMode: Text.WordWrap
                            font.pointSize: mainView.mediumFontSize
                            background: Rectangle {
                                color: "transparent"
                                border.color: "transparent"
                            }
                        }
                        Button {
                            id: pluginOkButton
                            anchors.right: parent.right
                            width: parent.width / 2 - mainView.innerSpacing / 2
                            padding: mainView.innerSpacing / 2
                            flat: true
                            text: qsTr("Ok")

                            contentItem: Text {
                                text: okButton.text
                                color: mainView.fontColor
                                font.pointSize: mainView.mediumFontSize
                                horizontalAlignment: Text.AlignHCenter
                            }

                            background: Rectangle {
                                color: "transparent"
                                border.color: "gray"
                            }

                            onClicked: {
                                pluginDialog.close()
                            }
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0
                    }
                }
            }

            Item {
                id: resetSettingsItem
                width: parent.width
                implicitHeight: resetSettingsItemColumn.height

                Column {
                    id: resetSettingsItemColumn
                    width: parent.width
                    spacing: mainView.innerSpacing  / 2
                    bottomPadding: mainView.innerSpacing * 2

                    property bool menuState: false

                    onMenuStateChanged: {
                        if (resetSettingsItemColumn.menuState) {
                            resetNewsButton.visible = true
                            timer.setTimeout(function() {
                                reseetShortcutsButton.visible = true
                                timer.setTimeout(function() {
                                    resetContactsButton.visible = true
                                    timer.setTimeout(function() {
                                        resetLauncherButton.visible = true
                                    }, 50)
                                }, 50)
                            }, 50)
                        } else {
                            resetLauncherButton.visible = false
                            timer.setTimeout(function() {
                                resetContactsButton.visible = false
                                timer.setTimeout(function() {
                                    reseetShortcutsButton.visible = false
                                    timer.setTimeout(function() {
                                        resetNewsButton.visible = false
                                    }, 50)
                                }, 50)
                            }, 50)
                        }
                    }

                    Timer {
                        id: timer
                        function setTimeout(cb, delayTime) {
                            timer.interval = delayTime
                            timer.repeat = false
                            timer.triggered.connect(cb)
                            timer.triggered.connect(function release () {
                                timer.triggered.disconnect(cb) // This is important
                                timer.triggered.disconnect(release) // This is important as well
                            })
                            timer.start()
                        }
                    }

                    HighlightButton {
                        id: resetSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        text: qsTr("Reset options")
                        boldText: resetSettingsItemColumn.menuState
                        onClicked: {
                            resetSettingsItemColumn.menuState = !resetSettingsItemColumn.menuState
                            settingsColumn.closeAllItemsExcept(resetSettingsItemColumn)
                        }
                    }

                    Button {
                        id: resetNewsButton
                        flat: true
                        highlighted: true
                        visible: false
                        x: mainView.innerSpacing
                        topPadding: mainView.innerSpacing / 2
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding:mainView.innerSpacing / 2
                        contentItem: Text {
                            width: parent.width - 2 * resetSettingsItemButton.padding
                            text: qsTr("Reset news feeds")
                            font.pointSize: mainView.mediumFontSize
                            font.weight: Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            id: resetNewsButtonBackground
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Universal.foreground
                            border.width: 1
                        }
                        onPressed: {
                            resetNewsButtonBackground.color = mainView.accentColor
                        }
                        onClicked: {
                            resetNewsButtonBackground.color = "transparent"
                            resetSettingsItemColumn.menuState = false
                            mainView.resetFeeds()
                        }
                    }

                    Button {
                        id: reseetShortcutsButton
                        flat: true
                        highlighted: true
                        visible: false
                        x: mainView.innerSpacing
                        topPadding: mainView.innerSpacing / 2
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing / 2
                        contentItem: Text {
                            width: parent.width - 2 * resetSettingsItemButton.padding
                            text: qsTr("Reset shorcuts")
                            font.pointSize: mainView.mediumFontSize
                            font.weight: Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            id: reseetShortcutsButtonBackground
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Universal.foreground
                            border.width: 1
                        }
                        onPressed: {
                            reseetShortcutsButtonBackground.color = mainView.accentColor
                        }
                        onClicked: {
                            reseetShortcutsButtonBackground.color = "transparent"
                            resetSettingsItemColumn.menuState = false
                            mainView.resetActions()
                        }
                    }

                    Button {
                        id: resetContactsButton
                        flat: true
                        highlighted: true
                        visible: false
                        x: mainView.innerSpacing
                        topPadding: mainView.innerSpacing / 2
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing / 2
                        contentItem: Text {
                            width: parent.width - 2 * resetSettingsItemButton.padding
                            text: qsTr("Reload contacts")
                            font.pointSize: mainView.mediumFontSize
                            font.weight: Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            id: resetContactsButtonBackground
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Universal.foreground
                            border.width: 1
                        }
                        onPressed: {
                            resetContactsButtonBackground.color = mainView.accentColor
                        }
                        onClicked: {
                            resetContactsButtonBackground.color = "transparent"
                            resetSettingsItemColumn.menuState = false
                            mainView.resetContacts()
                        }
                    }

                    Button {
                        id: resetLauncherButton
                        flat: true
                        highlighted: true
                        visible: false
                        x: mainView.innerSpacing
                        topPadding: mainView.innerSpacing / 2
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing / 2
                        contentItem: Text {
                            width: parent.width - 2 * resetSettingsItemButton.padding
                            text: qsTr("Reset launcher")
                            font.pointSize: mainView.mediumFontSize
                            font.weight: Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            id: reseetLauncherButtonBackground
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Universal.foreground
                            border.width: 1
                        }
                        onPressed: {
                            reseetLauncherButtonBackground.color = mainView.accentColor
                        }
                        onClicked: {
                            reseetLauncherButtonBackground.color = "transparent"
                            resetSettingsItemColumn.menuState = false
                            mainView.resetLauncher()
                        }
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
