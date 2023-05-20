import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12

Page {
    id: musicBoard

    Image {
        id: albomPic

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -50
        height: 300
        width: 300
        source: "/icons/albom.svg"
        antialiasing: true
        smooth: true
    }

    Text {
        id: songName

        anchors.topMargin: 10
        anchors.left: albomPic.left
        anchors.top: albomPic.bottom
        text: "Song name"
        color: "white"
    }

    Text {
        id: songAuthor

        anchors.topMargin: 10
        anchors.left: songName.left
        anchors.top: songName.bottom
        text: "Song author"
        color: "white"
    }
}