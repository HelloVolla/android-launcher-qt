import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12

Page {
    id: collectionPage
    anchors.fill: parent

    property var headline
    property var textInputField
    property string textInput
    property int currentCollectionMode: 3
    property var currentCollectionModel: peopleModel

    onTextInputChanged: {
        console.log("text input changed")
        currentCollectionModel.update(textInput)
    }

    Component.onCompleted: {
        textInput.text = ""
        currentCollectionModel.update("")
    }

    function updateCollectionMode (mode) {
        console.log("update collection model: " + mode)

        if (mode !== currentCollectionMode) {
            currentCollectionMode = mode

            switch (mode) {
                case swipeView.collectionMode.People:
                    headline.text = qsTr("People")
                    textInputField.placeholderText = "Find poeple ..."
                    currentCollectionModel = peopleModel
                    break;
                case swipeView.collectionMode.Threads:
                    headline.text = qsTr("Threads")
                    textInputField.placeholderText = "Find thread ..."
                    currentCollectionModel = threadModel
                    break;
                case swipeView.collectionMode.News:
                    headline.text = qsTr("News")
                    textInputField.placeholderText = "Find news ..."
                    currentCollectionModel = newsModel
                    break;
                default:
                    console.log("Unknown collection mode")
                    break;
            }
            currentCollectionModel.update(textInput)
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        headerPositioning: ListView.PullBackHeader

        header: Rectangle {
            id: header
            color: Universal.background
            width: parent.width
            implicitHeight: headerColumn.height
            Column {
                id: headerColumn
                width: parent.width
                Label {
                    id: headerLabel
                    topPadding: swipeView.innerSpacing
                    x: swipeView.innerSpacing
                    text: qsTr("Collection")
                    font.pointSize: swipeView.headerPointSize
                    font.weight: Font.Black
                    Binding {
                        target: collectionPage
                        property: "headline"
                        value: headerLabel
                    }
                }
                TextField {
                    id: textField
                    padding: swipeView.innerSpacing
                    x: swipeView.innerSpacing
                    width: parent.width -swipeView.innerSpacing * 2
                    placeholderText: qsTr("Filter collections")
                    color: Universal.foreground
                    placeholderTextColor: "darkgrey"
                    font.pointSize: swipeView.pointSize
                    leftPadding: 0.0
                    rightPadding: 0.0
                    background: Rectangle {
                        color: "black"
                        border.color: "transparent"
                    }

                    Binding {
                        target: collectionPage
                        property: "textInput"
                        value: textField.displayText.toLowerCase()
                    }

                    Binding {
                        target: collectionPage
                        property: "textInputField"
                        value: textField
                    }

                    Button {
                        id: deleteButton
                        visible: textField.activeFocus
                        text: "<font color='#808080'>×</font>"
                        font.pointSize: swipeView.pointSize * 2
                        flat: true
                        topPadding: 0.0
                        anchors.top: parent.top
                        anchors.right: parent.right

                        onClicked: {
                            textField.text = ""
                            textField.activeFocus = false
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    border.color: Universal.background
                    color: "transparent"
                    height: 1.1
                }
            }
        }

        model: currentCollectionModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: template.height

            Image {
                id: template
                anchors.top: parent.top
                source: model.source
                width: parent.width

                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                console.log("Collection item clicked")
                currentCollectionModel.executeSelection(model)
            }
            onPressAndHold: {
                console.log("Collection item pressed and hold")
                template.source = currentCollectionModel.openContextMenu(model)
                preventStealing = true
            }
            onExited: {
                console.log("Collection item exited")
                if (template.source.toString().split("/").pop() !== model.source.split("/").pop()) {
                    console.log("Source: " + template.source + ", " + model.source)
                    currentCollectionModel.executeContextMenuOption(model, mouseY, backgroundItem.height)
                    template.source = model.source
                }
                preventStealing = false
            }
            onCanceled: {
                console.log("Collection item exited")
                if (template.source.toString().split("/").pop() !== model.source.split("/").pop()) {
                    console.log("Source: " + template.source + ", " + model.source)
                    currentCollectionModel.executeContextMenuOption(model, mouseY, backgroundItem.height)
                    template.source = model.source
                }
                preventStealing = false
            }
        }
    }

    ListModel {
        id: peopleModel

        property var modelArr: [{"itemName": "Julia Herbst", "source": "/images/people01.png"},
                                {"itemName": "Lucille Bush", "source": "/images/people02.png"},
                                {"itemName": "Robert Schulz", "source": "/images/people03.png"},
                                {"itemName": "Clyde Bryant", "source": "/images/people04.png"},
                                {"itemName": "Fanny Adamie", "source": "/images/people05.png"},
                                {"itemName": "Duanne Moran", "source": "/images/people06.png"},
                                {"itemName": "Douglas Buttierny", "source": "/images/people07.png"},
                                {"itemName": "Albert Perez", "source": "/images/people08.png"},
                                {"itemName": "Jonathan Thorres", "source": "/images/people09.png"},
                                {"itemName": "Roy Pope", "source": "/images/people10.png"},
                                {"itemName": "Rosa Fleming", "source": "/images/people11.png"},
                                {"itemName": "Mina Montgomery", "source": "/images/people12.png"},
                                {"itemName": "Lucille Gonzales", "source": "/images/people13.png"}]

        function executeSelection(model) {
            if (model.itemName === "Julia Herbst") {
                swipeView.updateDetailPage("/images/contactTimeline.png", model.itemName, qsTr("Filter content ..."))
            }
        }

        function openContextMenu(model) {
            if (model.itemName === "Julia Herbst") {
                return "/images/people01.1.png"
            } else {
                return model.source
            }
        }

        function executeContextMenuOption(model, mouseY, modelItemHeight) {
            console.log("Execute context menu option: " + mouseY + ", " + modelItemHeight)
            var tolerance = 10
            if (mouseY > modelItemHeight / 2 - tolerance && mouseY < modelItemHeight / 2 + tolerance) {
                console.log("call Julia")
                Qt.openUrlExternally("tel:+491772448379")
            } else if (mouseY > modelItemHeight - tolerance && mouseY < modelItemHeight) {
                console.log("send email to Julia")
                Qt.openUrlExternally("mailto:info@volla.online")
            } else if (mouseY > modelItemHeight / 2) {
                console.log("send message to Julia")
                Qt.openUrlExternally("sms:+491772448379")
            }
        }

        function update(text) {
            console.log("Update model with text input: " + text)

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Model: " + modelArr)

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].itemName
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).itemName
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).itemName
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            for (modelItemName in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Will append " + filteredModelItem.itemName)
                    append(filteredModelDict[modelItemName])
                }
            }
        }
    }

    ListModel {
        id: threadModel

        property var modelArr: [{"itemName": "julia herbst hello have you read my ideas about the project", "source": "/images/threads01.png"},
                                {"itemName": "lola norris going away this weekend i will leave the keys with my neighbour tom call you later", "source": "/images/threads02.png"},
                                {"itemName": "gertrude hampton the book you recommended is awesome i will write a review love it", "source": "/images/threads03.png"},
                                {"itemName": "key murray i was looking through the notes you sent and there are some good comments in there let's", "source": "/images/threads04.png"},
                                {"itemName": "lloyed alvarado wanna grab some lunch", "source": "/images/threads05.png"},
                                {"itemName": "ben woodpeeker here are some photos of my vacation in the swill alps with my wife", "source": "/images/threads06.png"},
                                {"itemName": "pierre vaillant first studio recordings of good morning leon the recording with the trio are almost", "source": "/images/threads07.png"}];

        function executeSelection(model) {

        }

        function openContextMenu(model) {

        }

        function executeContextMenuOption(model, mouseY, modelItemHeight) {

        }

        function update(text) {
            console.log("Update model with text input: " + text)

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Model: " + modelArr)

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].itemName
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).itemName
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).itemName
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            for (modelItemName in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Will append " + filteredModelItem.itemName)
                    append(filteredModelDict[modelItemName])
                }
            }
        }
    }

    ListModel {
        id: newsModel

        property var modelArr: [{"itemName": " what makes people charismatic and how you can be too", "source": "/images/news01.png"},
                                {"itemName": " wmpressive views from the mountain tops in the swill alps :)", "source": "/images/news02.png"},
                                {"itemName": " a peak inside early stage venture capital strategies in europe", "source": "/images/news03.png"},
                                {"itemName": " cooking on a george forman gril", "source": "/images/news04.png"},
                                {"itemName": " maui hotel or maui condo one of the best places i have stayed in a long time", "source": "/images/news05.png"},
                                {"itemName": " what sci-fi tech tech computer science about ethics", "source": "/images/news06.png"},
                                {"itemName": " french cybercops dismantle pirate computer network", "source": "/images/news07.png"},
                                {"itemName": " overseas adventure travel in nepal most amaizing trip will go again 3", "source": "/images/news08.png"},
                                {"itemName": " deloitte's global millennial survey exploring a generation disrupted infographic", "source": "/images/news09.png"}]

        function executeSelection(model) {
            if (model.itemName.includes("charismatic")) {
                swipeView.updateDetailPage("/images/newsDetail01.png", "", "")
            }
        }

        function openContextMenu(model) {

        }

        function executeContextMenuOption(model, mouseY, modelItemHeight) {

        }

        function update(text) {
            console.log("Update model with text input: " + text)

            var filteredModelDict = new Object
            var filteredModelItem
            var modelItem
            var found
            var i

            console.log("Model: " + modelArr)

            for (i = 0; i < modelArr.length; i++) {
                filteredModelItem = modelArr[i]
                var modelItemName = modelArr[i].itemName
                if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
                    console.log("Add " + modelItemName + " to filtered items")
                    filteredModelDict[modelItemName] = filteredModelItem
                }
            }

            var existingGridDict = new Object
            for (i = 0; i < count; ++i) {
                modelItemName = get(i).itemName
                existingGridDict[modelItemName] = true
            }
            // remove items no longer in filtered set
            i = 0
            while (i < count) {
                modelItemName = get(i).itemName
                found = filteredModelDict.hasOwnProperty(modelItemName)
                if (!found) {
                    console.log("Remove " + modelItemName)
                    remove(i)
                } else {
                    i++
                }
            }

            // add new items
            for (modelItemName in filteredModelDict) {
                found = existingGridDict.hasOwnProperty(modelItemName)
                if (!found) {
                    // for simplicity, just adding to end instead of corresponding position in original list
                    filteredModelItem = filteredModelDict[modelItemName]
                    console.log("Will append " + filteredModelItem.itemName)
                    append(filteredModelDict[modelItemName])
                }
            }
        }
    }
}
