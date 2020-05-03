import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtWebView 1.12
import AndroidNative 1.0 as AN

Page {
    id: detailPage
    anchors.fill: parent

    property var currentDetailMode: 0
    property var currentDetailId
    property var currentDetailAuthorAndDate

    function updateDetailPage(mode, id, author, date) {
        console.log("DetailPage | Update detail page: " + id + ", " + mode)
        currentDetailMode = mode
        currentDetailId = id
        currentDetailAuthorAndDate = author !== undefined ? author  + "\n" + date : date

        switch (mode) {
        case mainView.detailMode.Web:
            prepareWebArticleView(id)
            break
        default:
            console.log("DetailPage | Mode not yet implemented")
            mainView.showToast(qsTr("Not yet supported"))
        }
    }

    function prepareWebArticleView (url) {
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("DetailPage | Received header status: " + doc.status);
                if (doc.status !== 200) {
                    mainView.showToast(qsTr("Failed to load article with status " + doc.status))
                }
            } else if (doc.readyState === XMLHttpRequest.DONE) {
                var message = {"url": url, "rawHTML": doc.responseText}
                AN.SystemDispatcher.dispatch("volla.launcher.articleAction", message)
            }
        }

        doc.open("GET", url);
        doc.send();
    }

    Flickable {
        id: detailFlickable
        width: parent.width
        height: parent.height
        contentWidth: parent.width
        contentHeight: detailColumn.height

        Column {
            id: detailColumn
            width: parent.width
            padding: mainView.innerSpacing
            spacing: mainView.innerSpacing

            Label {
                id: title
                width: parent.width - 2 * mainView.innerSpacing
                font.pointSize: mainView.headerFontSize
                font.weight: Font.Black
                color: Universal.foreground
                wrapMode: Text.WordWrap
            }
            Label {
                id: author
                width: parent.width - 2 * mainView.innerSpacing
                lineHeight: 1.1
                font.pointSize: mainView.smallFontSize
                color: Universal.foreground
                opacity: 0.7
                wrapMode: Text.WordWrap
            }
            Image {
                id: image
                sourceSize.width: parent.width - 2 * mainView.innerSpacing
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Label {
                id: text
                width: parent.width - 2 * mainView.innerSpacing
                lineHeight: 1.1
                font.pointSize: mainView.largeFontSize
                color: Universal.foreground
                wrapMode: Text.WordWrap
                linkColor: "lightgrey"
            }
        }
    }

    Connections {
        target: AN.SystemDispatcher
        onDispatched: {
            if (type === "volla.launcher.articleResponse") {
                console.log("DetailPage | onDispatched: " + type)
                console.log("DetailPage | title: " + message.title)
                console.log("DetailPage | image: " + message.imageUrl)
                console.log("DetailPage | video: " + message.videoUrl)
                title.text = message.title
                text.text = message.html
                image.source = message.imageUrl
                author.text = currentDetailAuthorAndDate
            }
        }
    }
}
