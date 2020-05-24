import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.12
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

Page {
    id : feedPage
    anchors.fill: parent

    property var headline
    property var headIcon
    property var textInputField
    property string textInput
    property real iconSize: 64.0
    property real headerIconSize: 52.0

    property int currentFeedMode: 0
    property string currentFeedId: ""
    property string currentFeedIcon: ""
    property var currentFeedModel: rssFeedModel

    property string n_ID:        "id"      // the id of the article or post
    property string n_STITLE:    "stitle"  // the author of the article or post
    property string n_TEXT:      "text"    // large main text, regular
    property string n_STEXT:     "stext"   // small text beyond the main text, grey
    property string n_IMAGE:     "image"   // preview image
    property string n_DATE:      "date"    // date in milliseconds of the item

    function updateFeedPage(mode, id, name, icon) {
        console.log("Feed | Update feed mode: " + mode + " with id " + id)

        if (mode !== currentFeedMode || currentFeedId !== id) {
            currentFeedMode = mode
            currentFeedModel.dropData()
            headline.text = name
            headIcon.source = icon
            currentFeedId = id

            switch (mode) {
                case mainView.feedMode.RSS:
                    currentFeedModel = rssFeedModel
                    rssFeedModel.source = currentFeedId
                    break;
                case mainView.feedMode.Twitter:
                    currentFeedModel = twitterFeedModel
                    // todo: load tweet data
                    break;
                default:
                    console.log("Feed | Unknown feed mode")
                    break;
            }
        }
    }

    onTextInputChanged: {
        console.log("FeedPage | Text input changed")
        currentFeedModel.update(textInput)
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
                Row {
                    topPadding: mainView.innerSpacing
                    leftPadding: mainView.innerSpacing
                    rightPadding: mainView.innerSpacing
                    spacing: mainView.innerSpacing * 0.75
                    Image {
                        id: headerIcon
                        source: ""
                        sourceSize: Qt.size(headerIconSize, headerIconSize)
                        smooth: true
                        visible: false

                        Desaturate {
                            anchors.fill: headerIcon
                            source: headerIcon
                            desaturation: 1.0

                        }
                        Binding {
                            target: feedPage
                            property: "headIcon"
                            value: headerIcon
                        }
                    }
                    Image {
                        source: "/images/contact-mask.png"
                        id: headerIconMask
                        sourceSize: Qt.size(headerIconSize, headerIconSize)
                        smooth: true
                        visible: false
                    }
                    OpacityMask {
                        id: iconOpacityMask
                        width: headerIconSize
                        height: headerIconSize
                        source: headerIcon
                        maskSource: headerIconMask
                    }
                    Label {
                        id: headerLabel
                        width: header.width - iconSize - (2 * mainView.innerSpacing)
                        text: qsTr("Feed")
                        clip: true
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: mainView.headerFontSize
                        font.weight: Font.Black
                        Binding {
                            target: feedPage
                            property: "headline"
                            value: headerLabel
                        }
                        LinearGradient {
                            id: headerLabelTruncator
                            height: headerLabel.height
                            width: headerLabel.width
                            start: Qt.point(headerLabel.width - 2 * mainView.innerSpacing,0)
                            end: Qt.point(headerLabel.width,0)
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: "#00000000"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Universal.background
                                }
                            }
                        }
                    }
                }
                TextField {
                    id: textField
                    padding: mainView.innerSpacing
                    x: mainView.innerSpacing
                    width: parent.width -mainView.innerSpacing * 2
                    placeholderText: qsTr("Filter news ...")
                    color: Universal.foreground
                    placeholderTextColor: "darkgrey"
                    font.pointSize: mainView.largeFontSize
                    leftPadding: 0.0
                    rightPadding: 0.0
                    background: Rectangle {
                        color: "transparent"
                        border.color: "transparent"
                    }
                    Binding {
                        target: feedPage
                        property: "textInput"
                        value: textField.displayText.toLowerCase()
                    }
                    Binding {
                        target: feedPage
                        property: "textInputField"
                        value: textField
                    }
                    Button {
                        id: deleteButton
                        visible: textField.activeFocus
                        text: "<font color='#808080'>×</font>"
                        font.pointSize: mainView.largeFontSize * 2
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
                    id: headerBottomSpace
                    width: parent.width
                    border.color: Universal.background
                    color: "transparent"
                    height: 1.1
                }
            }
            Rectangle {
                id: heeaderIconBorder
                anchors.top: header.top
                anchors.topMargin: mainView.innerSpacing
                anchors.left: header.left
                anchors.leftMargin: mainView.innerSpacing
                width: headerIcon.width
                height: headerIcon.height
                color: "transparent"
                border.color: Universal.foreground
                opacity: 0.7
                radius: headerIcon.width / 2
            }
        }

        model: currentFeedModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: newsBox.height + mainView.innerSpacing

            Rectangle {
                id: newsBox
                color: "transparent"
                width: parent.width
                implicitHeight: newsRow.height

                Row {
                    id: newsRow
                    topPadding: mainView.innerSpacing

                    Column {
                        id: newsColumn

                        Label {
                            id: newsAuthor
                            anchors.left: parent.left
                            leftPadding: mainView.innerSpacing
                            rightPadding: mainView.innerSpacing
                            width: newsBox.width - iconSize - mainView.innerSpacing
                            text: model.n_STITLE !== undefined ? model.n_STITLE : ""
                            lineHeight: 1.1
                            font.pointSize: mainView.smallFontSize
                            opacity: 0.7
                            visible: model.n_STITLE !== undefined && model.n_STITLE.length > 0
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            id: newsText
                            anchors.left: parent.left
                            topPadding: model.n_STITLE !== undefined && model.n_STITLE.length > 0 ? mainView.innerSpacing / 2 : 0
                            leftPadding: mainView.innerSpacing
                            rightPadding: mainView.innerSpacing
                            width: newsBox.width - iconSize - mainView.innerSpacing
                            text: model.n_TEXT
                            lineHeight: 1.1
                            font.pointSize: mainView.largeFontSize
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            id: newsDate
                            anchors.left: parent.left
                            topPadding: mainView.innerSpacing / 2
                            leftPadding: mainView.innerSpacing
                            rightPadding: mainView.innerSpacing
                            width: newsBox.width - iconSize - mainView.innerSpacing
                            text: getDateString()
                            lineHeight: 1.1
                            font.pointSize: mainView.smallFontSize
                            opacity: 0.7
                            visible: model.n_DATE !== undefined && model.n_DATE.length > 0
                            wrapMode: Text.WordWrap

                            function getDateString() {
                                var d = new Date(model.n_DATE)
                                var s = mainView.parseTime(d.valueOf())
                                console.log("FeedPage | " + d + ": " + s)
                                if (s.length > 0)
                                    return s
                                else
                                    return model.n_DATE
                            }
                        }
                    }
                    Image {
                        id: newsImage
                        horizontalAlignment: Image.AlignLeft
                        width: iconSize
                        height: iconSize
                        source: getImageUrl()
                        fillMode: Image.PreserveAspectCrop
                        visible: getImageUrl().length > 0

                        Desaturate {
                            anchors.fill: newsImage
                            source: newsImage
                            desaturation: 1.0
                        }

                        function getImageUrl() {
                            if (model.n_IMAGE !== undefined && model.n_IMAGE.length > 0) {
                                return model.n_IMAGE
                            } else if (model.n_THUMBNAIL !== undefined && model.n_THUMBNAIL.length > 0) {
                                return model.n_THUMBNAIL
                            } else if (model.n_ENCLOSURE !== undefined && model.n_ENCLOSURE.length > 0) {
                                return model.n_ENCLOSURE
                            } else {
                                return ""
                            }
                        }
                    }
                }
            }   

            onClicked: {
                currentFeedModel.executeSelection(model)
            }
        }
    }

    XmlListModel {
        id: rssFeedModel
        query: "/rss/channel/item"

        property string baseQuery: "/rss/channel/item"

        XmlRole {
            name: "n_TEXT"
            query: "title/string()"
        }
        XmlRole {
            name: "n_IMAGE"
            query: "*[local-name()='content'][1]/@url/string()"
        }
        XmlRole {
            name: "n_THUMBNAIL"
            query: "*[local-name()='thumbnail'][1]/@url/string()"
        }
        XmlRole {
            name: "n_ENCLOSURE"
            query: "enclosure/@url/string()"
        }
        XmlRole {
            name: "n_ID"
            query: "link/string()"
        }
        XmlRole {
            name: "n_DATE"
            query: "pubDate/string()"
        }
        XmlRole {
            name: "n_STITLE"
            query: "*[local-name()='creator']/string()"
        }

        function update(text) {
            console.log("Feed Page | Update RSS model with '" + text + "'")
            if (text.length > 0) {
                query = baseQuery + "[contains(title, '" + text + "')]"
            } else {
                query = baseQuery
            }
        }

        function dropData() {
            source = ""
        }

        function executeSelection(model) {
            console.log("FeedPage | News selected: " + model.n_ID)
            var author = model.n_STITLE !== undefined && model.n_STITLE.length > 0 ? headline.text + " • " + model.n_STITLE : headline.text
            mainView.updateDetailPage(mainView.detailMode.Web, model.n_ID, author, model.n_DATE)
        }
    }

    ListModel {
        id: twitterFeedModel

        function update(text) {

        }

        function dropData() {
            twitterFeedModel.clear()
        }

        function executeSelection(model) {
            mainView.showToast(qsTr("Not yet supported"))
        }
    }
}
