import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtWebView 1.12
import AndroidNative 1.0 as AN

Page {
    id: detailPage
    objectName: "detailPage"
    anchors.fill: parent
    topPadding: mainView.innerSpacing

    property var currentDetailMode: 0
    property var currentDetailId
    property var currentDetailAuthorAndDate

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    function updateDetailPage(mode, id, author, date) {
        console.log("DetailPage | Update detail page: " + id + ", " + mode)
        currentDetailMode = mode
        currentDetailId = id
        currentDetailAuthorAndDate = author !== undefined ? author  + "\n" + date : date
        resetContent()

        switch (mode) {
        case mainView.detailMode.Web:
            prepareWebArticleView(id)
            break
        default:
            console.log("DetailPage | Mode not yet implemented")
            mainView.showToast(qsTr("Not yet supported"))
        }
    }

    function resetContent() {
        title.text = ""
        author.text = ""
        image.source = ""
        text.text = ""
    }

    function prepareWebArticleView (url) {
        console.log("Will send XMLHTTPRequest for " + url)
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("DetailPage | Received header status: " + doc.status)
                if (doc.status !== 200) {
                    mainView.showToast(qsTr("Failed to load article with status " + doc.statusText))
                }
            } else if (doc.readyState === XMLHttpRequest.DONE) {
                console.log("DetailPage | Received response with status: " + doc.status)
                if (doc.status === 200) {
                    var message = {"url": url, "rawHTML": doc.responseText}
                    AN.SystemDispatcher.dispatch("volla.launcher.articleAction", message)
                } else {
                    text.text = qsTr("Couldn't load article. <a href=\"" + url + "\">Open in Browser.</a>")
                }
            }
        }
        doc.open("GET", url)
        doc.send()
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
            Row {
                width: parent.width
                spacing: mainView.innerSpacing
                Button {
                    id: openButton
                    text: qsTr("Open in browser")
                    font.pointSize: mainView.smallFontSize
                    visible: title.text.length > 0
                    rightPadding: mainView.innerSpacing
                    onClicked: {
                        console.log("Details | Open article")
                        Qt.openUrlExternally(detailPage.currentDetailId)
                    }
                }
                Button {
                    id: shareButton
                    text: qsTr("Share")
                    font.pointSize: mainView.smallFontSize
                    visible: title.text.length > 0
                    onClicked: {
                        console.log("Details | Share content")
                        an.shareContent(  {
                            mime_type: 'text/plain',
                            // , uri: single_uri
                            text: currentDetailId,
                            subject:  "This is a sample SUBJECT for sharing"
                            // , package: "com.whatsapp"
                            // url : "https://volla.online"
                        }  )
                    }
                }
            }
            Label {
                id: text
                width: parent.width - 2 * mainView.innerSpacing
                lineHeight: 1.1
                font.pointSize: mainView.largeFontSize
                color: Universal.foreground
                wrapMode: Text.WordWrap
                linkColor: "lightgrey"

                onLinkActivated: Qt.openUrlExternally(link)
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
//                console.log("DetailPage | html: " + message.html)
                title.text = message.title

                var html = message.html.replace("<h1>", "<strong>")
                html = html.replace("</h1>", "</strong>")
                html = html.replace(/((<p>){2,})/g, "<p>")
                html = html.replace(/((<\/p>){2,})/g, "</p>")
//                console.log("DetailPage | html: " + html)

                text.text = html
                image.source = message.imageUrl
                author.text = currentDetailAuthorAndDate
            }
        }
    }

    // @disable-check M300
    AN.Share {
        id: an
    }
}
