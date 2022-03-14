import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Universal 2.12
import Qt.labs.settings 1.0
import AndroidNative 1.0 as AN

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
                            color: themeSettingsItem.menuState === true ? Universal.accent : "transparent"
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
                        visible: themeSettingsItem.menuState
                        text: qsTr("Dark Mode")
                        contentItem: Text {
                            text: darkModeOption.text
                            font.pointSize: mainView.mediumFontSize
                            font.weight: themeSettingsItem.selectedMenuItem === darkModeOption ? Font.Black : Font.Normal
                            color: "white"
                            opacity: themeSettingsItem.labelOpacity
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: themeSettingsItem.menuState ? Universal.accent : "transparent"
                        }
                    }
                    Button {
                        id: lightModeOption

                        property var theme: mainView.theme.Light

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing
                        width: parent.width
                        visible: themeSettingsItem.menuState
                        text: qsTr("Light Mode")
                        contentItem: Text {
                            text: lightModeOption.text
                            font.pointSize: mainView.mediumFontSize
                            font.weight: themeSettingsItem.selectedMenuItem === lightModeOption ? Font.Black : Font.Normal
                            color: "white"
                            opacity: themeSettingsItem.labelOpacity
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: themeSettingsItem.menuState ? Universal.accent : "transparent"
                        }
                    }
                    Button {
                        id: translucentModeOption

                        property var theme: mainView.theme.Translucent

                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing * 2
                        width: parent.width
                        visible: themeSettingsItem.menuState
                        text: qsTr("Translucent Mode")
                        contentItem: Text {
                            text: translucentModeOption.text
                            font.pointSize: mainView.mediumFontSize
                            font.weight: themeSettingsItem.selectedMenuItem === translucentModeOption ? Font.Black : Font.Normal
                            color: "white"
                            opacity: themeSettingsItem.labelOpacity
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: themeSettingsItem.menuState ? Universal.accent : "transparent"
                        }
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
                                font.pointSize: mainView.largeFontSize
                                font.weight: securitySettingsItem.menuState ? Font.Black : Font.Normal
                                color: securitySettingsItem.menuState ? "white" : Universal.foreground
                            }
//                            Image {
//                                id: name
//                                source: "file"
//                            }
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: securitySettingsItem.menuState === true ? Universal.accent : "transparent"
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
                            color: securitySettingsItem.menuState ? Universal.accent : "transparent"
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
                        text: qsTr("Security mode if ON")
                        contentItem: Row {
                            Text {
                                text: securityModeOnOption.text
                                font.pointSize: mainView.mediumFontSize
                                font.weight: securitySettingsItem.selectedMenuItem === securityModeOnOption ? Font.Black : Font.Normal
                                color: "white"
                                opacity: securitySettingsItem.labelOpacity
                            }
//                            Image {
//                                source: "file"
//                            }
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: securitySettingsItem.menuState ? Universal.accent : "transparent"
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
                    console.log("Settings | Current mode: " + Universal.theme + ", " + themeSettings.theme)
                    console.log("Settings | Execute mode selection: " + selectedMenuItem.text + ", " + selectedMenuItem.isActiveSecurityMode)
                    if (securitySettingsItemTitle.text !== selectedMenuItem.text
                            && selectedMenuItem !== securitySettingsItemTitle) {
                        passwordDialog.open()
                    }
                }

                Dialog {
                    id: passwordDialog

                    anchors.centerIn: parent
                    implicitHeight: dialogColumn.height
                    width: 300
                    //title: qsTr("Enter password")
                    modal: true
                    dim: false

                    background: Rectangle {
                        anchors.fill: parent
                        color: #5b5b5b
                        border.color: "transparent"
                        radius: mainView.innerSpacing
                    }

                    contentItem: Column {
                        id: dialogColumn
                        spacing: mainView.innerSpacing

                        Label {
                            text: qsTr("Enter password")
                            color: mainView.fontColor
                            font.pointSize: mainView.mediumFontSize
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
                                color: mainView.backgroundColor
                                border.color: "transparent"
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: mainView.innerSpacing

                            Button {
                                flat: true
                                width: parent.width / 2 - mainView.innerSpacing
                                text: qsTr("Cancel")
                            }

                            Button {
                                width: parent.width / 2 - mainView.innerSpacing * 3
                                flat: true
                                text: qsTr("Ok")
                            }
                        }
                    }

                    //standardButtons: Dialog.Ok | Dialog.Cancel

                    onAccepted: {
                        AN.SystemDispatcher.dispatch(
                                    "volla.launcher.securityModeAction",
                                    {"password": passwordField.text,
                                     "activate": securitySettingsItem.selectedMenuItem === securityModeOnOption})
                    }
                    onRejected: {
                        securitySettingsItem.selectedMenuItem = securitySettingsItemTitle
                    }
                }

                Connections {
                    target: AN.SystemDispatcher

                    onDispatched: {
                        if (type === "volla.launcher.securityModeResponse") {
                            if (message["succeeded"]) {
                                securitySettingsItemTitle.text = selectedMenuItem.text
                                securitySettings.isActiveSecurityMode = selectedMenuItem.isActiveSecurityMode
                                securitySettingsItem.selectedMenuItem = securitySettingsItemTitle
                            } else {
                                mainView.showToast(qsTr("Wrong password"))
                            }
                        } else if (type === "volla.launcher.securityStateResponse") {
                            securitySettingsItemTitle.text = message["isActive"] ? securityModeOnOption.text
                                                                                 : securityModeOffOption.text
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

                    Button {
                        id: newsSettingsItemTitle
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * newsSettingsItemTitle.padding
                            text: qsTr("News Channels")
                            font.pointSize: mainView.largeFontSize
                            font.weight: newsSettingsItemColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            newsSettingsItemColumn.menuState = !newsSettingsItemColumn.menuState
                            if (newsSettingsItemColumn.menuState) {
                                console.log("Settings | Will create new checkboxes")
                                newsSettingsItemColumn.createCheckboxes()
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
                                "text": cannels[i]["name"], "checked": cannels[i]["activated"],
                                "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                "hasRemoveButton": true}
                            var object = component.createObject(newsSettingsItemColumn, properties)
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

                    Button {
                        id: shortcutSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * shortcutSettingsItemButton.padding
                            text: qsTr("Shortcuts")
                            font.pointSize: mainView.largeFontSize
                            font.weight: shortcutSettingsItemColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            shortcutSettingsItemColumn.menuState = !shortcutSettingsItemColumn.menuState
                            if (shortcutSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                shortcutSettingsItemColumn.createCheckboxes()
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
                                "hasRemoveButton": getFilteredShortcuts(mainView.defaultActions, "id", shortcuts[i]["id"]).length === 0 }
                            var object = component.createObject(shortcutSettingsItemColumn, properties)
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
                            "hasRemoveButton": true }
                        var object = component.createObject(shortcutSettingsItemColumn, properties)
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
                        color: Universal.accent
                        radius: mainView.innerSpacing
                    }

                    contentItem: ListView {
                        id: appList
                        delegate: Button {
                            width: parent.width
                            font.pointSize: mainView.mediumFontSize
                            leftPadding: mainView.innerSpacing
                            rightPadding: mainView.innerSpacing
                            topPadding: mainView.innerSpacing
                            bottomPadding: index === appMenuModel.count - 1 ? mainView.innerSpacing : 0
                            flat: true
                            text: model.label
                            background: Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                            }
                            onClicked: {
                                console.log("Settings | App " + model["label"] + " selected for shortcuts");
                                mainView.updateAction(
                                            model["itemId"], true, mainView.settingsAction.CREATE,
                                            {"id": model["itemId"], "name": qsTr("Open") + " " + model["label"], "activated": true} )
                                appMenuModel.append(
                                            {"id": model["itemId"], "name": qsTr("Open") + " " + model["label"], "activated": true} )

                                var component = Qt.createComponent("/Checkbox.qml", shortcutSettingsItemColumn)
                                var properties = { "actionId": model["itemId"],
                                    "text": qsTr("Open") + " " + model["label"], "checked": true,
                                    "labelFontSize": mainView.mediumFontSize, "circleSize": mainView.largeFontSize,
                                    "leftPadding": mainView.innerSpacing, "rightPadding": mainView.innerSpacing,
                                    "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2,
                                    "hasRemoveButton": true }
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

            // todo: Add source settings

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

                    Button {
                        id: searchSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * shortcutSettingsItemButton.padding
                            text: qsTr("Search engines")
                            font.pointSize: mainView.largeFontSize
                            font.weight: shortcutSettingsItemColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            searchSettingsItemColumn.menuState = !searchSettingsItemColumn.menuState
                            if (searchSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                searchSettingsItemColumn.createCheckboxes()
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
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2 }
                        var object = component.createObject(searchSettingsItemColumn, properties)
                        searchSettingsItemColumn.checkboxes.push(object)
                        component = Qt.createComponent("/Checkbox.qml", searchSettingsItemColumn)
                        properties["actionId"] = "startpage"
                        properties["text"] = qsTr("Startpage")
                        properties["checked"] = mainView.getSearchMode() === mainView.searchMode.StartPage
                        object = component.createObject(searchSettingsItemColumn, properties)
                        searchSettingsItemColumn.checkboxes.push(object)
                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "metager"
                        properties["text"] = qsTr("MetaGer")
                        properties["checked"] = mainView.getSearchMode() === mainView.searchMode.MetaGer
                        object = component.createObject(searchSettingsItemColumn, properties)
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

                    Button {
                        id: designSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * shortcutSettingsItemButton.padding
                            text: qsTr("Display and menus")
                            font.pointSize: mainView.largeFontSize
                            font.weight: shortcutSettingsItemColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            designSettingsItemColumn.menuState = !designSettingsItemColumn.menuState
                            if (designSettingsItemColumn.menuState) {
                                console.log("Settings | Will create checkboxes")
                                designSettingsItemColumn.createCheckboxes()
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
                                "bottomPadding": mainView.innerSpacing / 2, "topPadding": mainView.innerSpacing / 2 }
                        var object = component.createObject(designSettingsItemColumn, properties)
                        designSettingsItemColumn.checkboxes.push(object)
                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "coloredIcons"
                        properties["text"] = qsTr("Use colored app icons")
                        properties["checked"] = designSettings.useColoredIcons
                        object = component.createObject(designSettingsItemColumn, properties)
                        designSettingsItemColumn.checkboxes.push(object)
                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "startupIndex"
                        properties["text"] = qsTr("Show apps at startup")
                        properties["checked"] = designSettings.showAppsAtStartup
                        object = component.createObject(designSettingsItemColumn, properties)
                        designSettingsItemColumn.checkboxes.push(object)
                        component = Qt.createComponent("/Checkbox.qml", designSettingsItemColumn)
                        properties["actionId"] = "hapticMenus"
                        properties["text"] = qsTr("Use haptic menus")
                        properties["checked"] = designSettings.useHapticMenus
                        object = component.createObject(designSettingsItemColumn, properties)
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
                            if (active) {
                                mainView.updateVisibility(5)
                            } else {
                                mainView.updateVisibility(2)
                            }
                        } else if (actionId === "coloredIcons") {
                            designSettings.useColoredIcons = active
                            designSettings.sync()
                            mainView.updateGridView(active)
                        } else if (actionId === "startupIndex") {
                            designSettings.showAppsAtStartup = active
                            designSettings.sync()
                        } else if (actionId === "hapticMenus") {
                            designSettings.useHapticMenus = active
                            designSettings.sync()
                            mainView.useVibration = active
                        }
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250.0

                        onRunningChanged: {
                            console.log("Settings | Running changed to " + running)
                            if (!running) {
                                blurLabel.visible = !blurLabel.visible
                                blurSlider.visible = !blurSlider.visible
                            }
                        }
                    }
                }

                Settings {
                    id: designSettings
                    property bool fullscreen: false
                    property bool useColoredIcons: false
                    property bool showAppsAtStartup: false
                    property bool useHapticMenus: false
                    property double blurEffect: 60
                }
            }

            Label {
                id: blurLabel
                topPadding: mainView.innerSpacing
                leftPadding: mainView.innerSpacing
                rightPadding: mainView.innerSpacing
                text: qsTr("Background blur")
                font.pointSize: mainView.mediumFontSize
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

                handle: Rectangle {
                    x: blurSlider.leftPadding + blurSlider.visualPosition * (blurSlider.availableWidth - width)
                    y: blurSlider.topPadding + blurSlider.availableHeight / 2 - height / 2
                    implicitWidth: mainView.largeFontSize
                    implicitHeight: mainView.largeFontSize
                    radius: mainView.largeFontSize / 2
                    color: Universal.accent
                    border.color: Universal.accent
                }

                onValueChanged: {
                    console.log("Settings | Blurr filter chanded to " + value)
                    designSettings.blurEffect = value
                    mainView.updateBlurEffect(value)
                }
            }

            Item {
                id: resetSettingsItem
                width: parent.width

                implicitHeight: resetSettingsItemColumn.height

                Column {
                    id: resetSettingsItemColumn
                    width: parent.width
                    spacing: mainView.innerSpacing / 2

                    property bool menuState: false

                    Button {
                        id: resetSettingsItemButton
                        width: parent.width
                        padding: mainView.innerSpacing
                        contentItem: Text {
                            width: parent.width - 2 * resetSettingsItemButton.padding
                            text: qsTr("Reset options")
                            font.pointSize: mainView.largeFontSize
                            font.weight: resetSettingsItemColumn.menuState ? Font.Black : Font.Normal
                            color: Universal.foreground
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                        onClicked: {
                            resetSettingsItemColumn.menuState = !resetSettingsItemColumn.menuState
                        }
                    }

                    Button {
                        id: resetNewsButton
                        flat: true
                        highlighted: true
                        visible: resetSettingsItemColumn.menuState
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
                            resetNewsButtonBackground.color = Universal.accent
                        }
                        onClicked: {
                            resetNewsButtonBackground.color = "transparent"
                            newsSettingsItemColumn.menuState = false
                            newsSettingsItemColumn.destroyCheckboxes()
                            mainView.resetFeeds()
                        }
                    }

                    Button {
                        id: reseetShortcutsButton
                        flat: true
                        highlighted: true
                        visible: resetSettingsItemColumn.menuState
                        x: mainView.innerSpacing
                        topPadding: mainView.innerSpacing / 2
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing / 2
                        contentItem: Text {
                            width: parent.width - 2 * resetSettingsItemButton.padding
                            text: qsTr("Reset shorcuts feeds")
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
                            reseetShortcutsButtonBackground.color = Universal.accent
                        }
                        onClicked: {
                            reseetShortcutsButtonBackground.color = "transparent"
                            shortcutSettingsItemColumn.menuState = false
                            shortcutSettingsItemColumn.destroyCheckboxes()
                            mainView.resetActions()
                        }
                    }

                    Button {
                        id: resetLauncherButton
                        flat: true
                        highlighted: true
                        visible: resetSettingsItemColumn.menuState
                        x: mainView.innerSpacing
                        topPadding: mainView.innerSpacing / 2
                        leftPadding: mainView.innerSpacing
                        rightPadding: mainView.innerSpacing
                        bottomPadding: mainView.innerSpacing / 2
                        contentItem: Text {
                            width: parent.width - 2 * resetSettingsItemButton.padding
                            text: qsTr("Reset this app")
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
                            reseetLauncherButtonBackground.color = Universal.accent
                        }
                        onClicked: {
                            reseetLauncherButtonBackground.color = "transparent"
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


