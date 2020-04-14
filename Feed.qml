import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.13
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

Page {
    id : feedPage
    anchors.fill: parent

    property var headline
    property var textInputField
    property string textInput
    property real iconSize: 64.0

    property var currentFeedModel: rssFeedModel



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
                    text: qsTr("Feed")
                    font.pointSize: swipeView.headerFontSize
                    font.weight: Font.Black
                    Binding {
                        target: feedPage
                        property: "headline"
                        value: headerLabel
                    }
                }
                TextField {
                    id: textField
                    padding: swipeView.innerSpacing
                    x: swipeView.innerSpacing
                    width: parent.width -swipeView.innerSpacing * 2
                    placeholderText: qsTr("Filter news ...")
                    color: Universal.foreground
                    placeholderTextColor: "darkgrey"
                    font.pointSize: swipeView.largeFontSize
                    leftPadding: 0.0
                    rightPadding: 0.0
                    background: Rectangle {
                        color: "black"
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
                        font.pointSize: swipeView.largeFontSize * 2
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

        model: currentFeedModel

        delegate: MouseArea {
            id: backgroundItem
            width: parent.width
            implicitHeight: newsBox.height + swipeView.innerSpacing

            Rectangle {
                id: newsBox
                color: "transparent"
                width: parent.width
                implicitHeight: newsRow.height

                Row {
                    id: newsRow

                    Column {
                        id: newsColumn

                        Label {

                        }
                        Label {

                        }
                        Label {

                        }
                    }
                    Image {
                        id: newsImage

                    }
                }
            }
        }
    }

    XmlListModel {
        id: rssFeedModel

        function update(text) {

        }
    }

    ListModel {
        id: twitterFeedModel

        function update(text) {

        }
    }
}
