import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.2

Page {
    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }
    anchors.topMargin: Screen.desktopAvailableWidth > 520 ? 22 : 0
    anchors.bottomMargin: Screen.desktopAvailableWidth > 520 ? 22 : 0
    anchors.leftMargin: Screen.desktopAvailableWidth > 520 ? 100 : 0
    anchors.rightMargin: Screen.desktopAvailableWidth > 520 ? 100 : 0

    FontLoader {
        source: "qrc:/fonts/NotoColorEmoji_WindowsCompatible.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Poppins-Regular.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Poppins-Bold.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Poppins-Italic.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/selawk.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/selawkb.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Lato-Regular.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Lato-Bold.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Lato-Italic.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Rubik-Regular.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Rubik-Bold.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/Rubik-Italic.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/IBMPlexSans-Regular.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/IBMPlexSans-Bold.ttf"
    }

    FontLoader {
        source: "qrc:/fonts/IBMPlexSans-Italic.ttf"
    }
}
