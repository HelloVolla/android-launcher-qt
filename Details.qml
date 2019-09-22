import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12

Page {
    id: detailPage
    anchors.fill: parent

    property var headline
    property var detailImage
    property var textInputField

    function updateDetailPage(imageSource, headlineText, placeholderText) {
        console.log("Update detail image " + imageSource + ", " + placeholderText)
        detailImage.source = imageSource
        headline.text = headlineText
        textInputField.placeholderText = placeholderText

        if (headlineText.length === 0 || placeholderText.length === 0) {
            header.visible = false
        } else {
            header.visible = true
        }
    }

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
                text: qsTr("Details")
                font.pointSize: swipeView.headerPointSize
                font.weight: Font.Black
                Binding {
                    target: detailPage
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
                    target: detailPage
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

    Flickable {
        width: parent.width
        height: parent.height
        contentWidth: parent.width
        contentHeight: 3000 // todo: use dynamic value

        Image {
            id: image
            source: "/images/contactTimeline.png"
            width: parent.width
            fillMode: Image.PreserveAspectFit

            Binding {
                target: detailPage
                property: "detailImage"
                value: image
            }
        }
    }
}
