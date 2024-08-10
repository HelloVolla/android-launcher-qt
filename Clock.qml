import QtQuick 2.0

Item {
    id : clock
        width: 160
        height: 160
        transformOrigin: Item.Top
        property string city
        property int hours
        property int minutes
        property int seconds
        property real shift
        property bool night: false
        property bool internationalTime: true //Unset for local time

        function timeChanged() {
            var date = new Date;
            hours = internationalTime ? date.getUTCHours() + Math.floor(clock.shift) : date.getHours()
            night = ( hours < 7 || hours > 19 )
            minutes = internationalTime ? date.getUTCMinutes() + ((clock.shift % 1) * 60) : date.getMinutes()
            seconds = date.getUTCSeconds();
        }

        Timer {
            interval: 100; running: true; repeat: true;
            onTriggered: clock.timeChanged()
        }

        Item {
            width: 160
            height: 160
            anchors.leftMargin: 10
            anchors.topMargin: 10
            anchors.fill: parent
            anchors.right: parent.right

            Image { id: background; width: 160; height: 160; source: "images/Clock_01_white.png"; visible: clock.night == false }
            Image { width: 160; height: 160; source: "images/Clock_01_black.png"; visible: clock.night == true }


            Image {
                x: 76; y: 10
                height: 140
                rotation: -149.35
                z: 5
                transformOrigin: Item.Center
                clip: false
                source: "images/01-white_hours.png"
                transform: Rotation {
                    id: hourRotation
                    origin.x: 7.5; origin.y: 73;
                    angle: (clock.hours * 30) + (clock.minutes * 0.5)
                    Behavior on angle {
                        SpringAnimation { spring: 2; damping: 0.2; modulus: 360 }
                    }
                }
            }

            Image {
                x: 74.7; y: 9.2
                width: 6
                height: 140
                z: 6
                rotation: -59.09
                source: "images/01-white_minutes.png"
                transform: Rotation {
                    id: minuteRotation
                    origin.x: 7.5; origin.y: 73;
                    angle: clock.minutes * 6
                    Behavior on angle {
                        SpringAnimation { spring: 2; damping: 0.2; modulus: 360 }
                    }
                }
            }

            Image {
                x: 73.8; y: 9
                width: 6
                height: 140
                z: 10
                rotation: 0.04
                source: "images/01-white_seconds.png"
                transform: Rotation {
                    id: secondRotation
                    origin.x: 7.5; origin.y: 70;
                    angle: clock.seconds * 6
                    Behavior on angle {
                        SpringAnimation { spring: 2; damping: 0.2; modulus: 360 }
                    }
                }
            }

            Image {
                x: 70
                width: 20
                height: 20
                transformOrigin: Item.Center
                anchors.centerIn: background; source: "images/center.png"
            }

            Text {
                id: cityLabel
                y: 210; anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                font.family: "Helvetica"
                font.bold: true; font.pixelSize: 16
                style: Text.Raised; styleColor: "black"
                text: clock.city
            }
        }

}



/*##^##
Designer {
    D{i:2;anchors_height:170;anchors_width:170;anchors_x:0;anchors_y:0}
}
##^##*/
