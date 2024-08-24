import QtQuick 2.0

Item {
    id : clock
        width: 160
        height: 160
        transformOrigin: Item.Top
        property int hours
        property int minutes
        property int seconds
        property real shift : 2
        property bool night: false
        property bool internationalTime: false //Unset for local time

        function timeChanged() {
            var date = new Date;
            hours = internationalTime ? date.getUTCHours() + Math.floor(clock.shift) : date.getHours()
            night = ( hours < 7 || hours > 19 )
            minutes = internationalTime ? date.getUTCMinutes() + ((clock.shift % 1) * 60) : date.getMinutes()
            seconds = date.getUTCSeconds();
        }

        Timer {
            interval: 1000; running: true; repeat: true;
            onTriggered: clock.timeChanged()
        }

        Item {
            width: 160
            height: 160
            anchors.leftMargin: 10
            anchors.topMargin: 10
            anchors.fill: parent
            anchors.right: parent.right

            Image { id: background; width: 160; height: 160;
                source: mainView.backgroundColor === "white" ? "images/Clock_01_black.png" : "images/Clock_01_white.png"
                visible: clock.night == false }

            Image { width: 160; height: 160;
                source: mainView.backgroundColor === "white" ? "images/Clock_01_black.png" : "images/Clock_01_white.png"
                visible: clock.night == true }


            Image {
                x: 76; y: 10
                height: 140
                z: 1
                source: mainView.backgroundColor === "white" ? "images/01-black_hours.png": "images/01-white_hours.png"
                transform: Rotation {
                    id: hourRotation
                    origin.x: 4; origin.y: 70;
                    angle: (clock.hours * 30) + (clock.minutes * 0.5)
                    Behavior on angle {
                        SpringAnimation { spring: 2; damping: 0.2; modulus: 360 }
                    }
                }
            }

            Image {
                x: 76; y: 9.2
                width: 6
                height: 140
                z: 5
                source: mainView.backgroundColor === "white" ?  "images/01-black_minutes.png" : "images/01-white_minutes.png"
                transform: Rotation {
                    id: minuteRotation
                    origin.x: 4; origin.y: 70;
                    angle: clock.minutes * 6
                    Behavior on angle {
                        SpringAnimation { spring: 2; damping: 0.2; modulus: 360 }
                    }
                }
            }

            Image {
                x: 77; y: 9.4
                width: 6
                height: 140
                z: 6
                source: "images/01-white_seconds.png"
                transform: Rotation {
                    id: secondRotation
                    origin.x: 2.7; origin.y: 70;
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
                z: 10
                transformOrigin: Item.Center
                anchors.centerIn: background; source: "images/center.png"
            }
        }
}
