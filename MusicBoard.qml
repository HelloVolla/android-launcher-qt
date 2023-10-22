import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import AndroidNative 1.0 as AN

Page {
    id: musicBoard

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Label {
        id: headerTitle

        topPadding: mainView.innerSpacing * 2
        x: mainView.innerSpacing
        text: qsTr("Music Board")
        font.pointSize: mainView.headerFontSize
        font.weight: Font.Black
    }

    Item {
        id: albumPic

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -50
        height: 300
        width: 300

        property alias source: playerAlbumPic.source

        ColoredImage {
            anchors.fill: parent
            source: "/icons/album.svg"
            color: Universal.foreground
            visible: !playerAlbumPic.visible
        }

        Image {
            id: playerAlbumPic

            anchors.fill: parent
            antialiasing: true
            visible: source.toString() !== ""
        }
    }

    Text {
        id: trackName

        anchors.topMargin: 10
        anchors.left: albumPic.left
        anchors.top: albumPic.bottom
        text: ""
        color: Universal.foreground
    }

    Text {
        id: trackAuthor

        anchors.topMargin: 10
        anchors.left: trackName.left
        anchors.top: trackName.bottom
        text: ""
        color: Universal.foreground
    }

    Button {
        id: previousTrack

        anchors.left: albumPic.left
        anchors.top: trackAuthor.bottom
        height: 48
        width: 48
        background: Rectangle {
            anchors.fill: parent
            color: "transparent"
        }
        contentItem: ColoredImage {
            anchors.fill: parent
            source: "/icons/previous.svg"
            color: Universal.foreground
        }

        onClicked: {
            AN.SystemDispatcher.dispatch("volla.launcher.prevTrack", new Object)
        }
    }

    Button {
        id: nextTrack

        anchors.right: albumPic.right
        anchors.top: trackAuthor.bottom
        height: 48
        width: 48
        background: Rectangle {
            anchors.fill: parent
            color: "transparent"
        }
        contentItem: ColoredImage {
            anchors.fill: parent
            source: "/icons/next.svg"
            color: Universal.foreground
        }

        onClicked: {
            AN.SystemDispatcher.dispatch("volla.launcher.nextTrack", new Object)
        }
    }

    Button {
        id: playButton

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: trackAuthor.bottom
        height: 48
        width: 48
        background: Rectangle {
            anchors.fill: parent
            color: "transparent"
        }

        property bool playing: false

        contentItem: Item {
            anchors.fill: parent

            ColoredImage {
                anchors.fill: parent
                source: "/icons/pause.svg"
                color: Universal.foreground
                visible: playButton.playing
            }

            ColoredImage {
                anchors.fill: parent
                source: "/icons/play.svg"
                color: Universal.foreground
                visible: !playButton.playing
            }
        }

        onClicked: {
            AN.SystemDispatcher.dispatch("volla.launcher.playPauseTrack", new Object)
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.trackChanged") {
                trackName.text = message["trackName"];
                trackAuthor.text = message["trackAuthor"];
                console.log("MusicBoard |", message["albumPic"]);
                if (message["albumPic"] && message["albumPic"].length !== 0) {
                    albumPic.source = "data:image/png;base64," + message["albumPic"];
                } else {
                    albumPic.source = "";
                }
            } else if (type === "volla.launcher.gotPlayingStatus") {
                playButton.playing = message["playingStatus"];
            }
        }
    }
}