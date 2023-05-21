import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import AndroidNative 1.0 as AN

Page {
    id: musicBoard

    Image {
        id: albomPic

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -50
        height: 300
        width: 300
        source: private_.defaultAlbumPic
        antialiasing: true
        smooth: true
    }

    Text {
        id: trackName

        anchors.topMargin: 10
        anchors.left: albomPic.left
        anchors.top: albomPic.bottom
        text: ""
        color: "white"
    }

    Text {
        id: trackAuthor

        anchors.topMargin: 10
        anchors.left: trackName.left
        anchors.top: trackName.bottom
        text: ""
        color: "white"
    }


    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.trackChanged") {
                trackName.text = message["trackName"];
                trackAuthor.text = message["trackAuthor"];
                console.log("MusicBoard |", message["albumPic"]);
                if (message["albumPic"] && message["albumPic"].length !== 0) {
                    albomPic.source = "data:image/png;base64," + message["albumPic"];
                } else {
                    albomPic.source = private_.defaultAlbumPic;
                }
            }
        }
    }

    QtObject {
        id: private_

        readonly property string defaultAlbumPic: "/icons/albom.svg";
    }
}