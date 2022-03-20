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
    property var currentTitle

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    function updateDetailPage(mode, id, author, date, title) {
        console.log("DetailPage | Update detail page: " + id + ", " + mode)
        currentDetailMode = mode
        currentDetailId = id !== undefined ? id : Date.now()
        currentDetailAuthorAndDate = author !== undefined ? author  + "\n" + date : date
        currentTitle = title !== undefined ? title : undefined
        resetContent()

        switch (mode) {
        case mainView.detailMode.Web:
            prepareWebArticleView(id)
            break
        case mainView.detailMode.Note:
            prepareNoteView(title)
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
        //notePad.text = ""
        dummy.visible = false
    }

    function prepareWebArticleView(url) {
        console.log("Will send XMLHTTPRequest for " + url)
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("DetailPage | Received header status: " + doc.status)
                if (doc.status >= 400) {
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

    function prepareNoteView(note) {
        console.log("Details | note: " + note)
        //notePad.text = "#" + note
        dummy.visible = true
        if (note === undefined) {
            dummyImage.source = Qt.resolvedUrl("images/02.Notes_Screen.png")
            detailPage.currentDetailId = "02.Notes"
        } else {
            dummyImage.source = Qt.resolvedUrl("images/05.Notes_Screen.png")
            detailPage.currentDetailId = "05.Notes"
        }
    }

    Button {
        id: dummy
        flat: true
        anchors.fill: parent
        display: AbstractButton.IconOnly
        z:2
        visible: false

        background: Rectangle {
            color: "transparent"
            border.color: "transparent"
        }

        contentItem: Image {
            id: dummyImage
            anchors.top: parent.top
            fillMode: Image.PreserveAspectFit
            cache: false
        }

        onClicked: {
            console.log("Details | Dummy clicked: " + detailPage.currentDetailId)
            if (detailPage.currentDetailId === "02.Notes") {
                dummyImage.source = Qt.resolvedUrl("images/03.Notes_Screen.png")
                detailPage.currentDetailId = "03.Notes"
            } else if (detailPage.currentDetailId === "03.Notes") {
                dummyImage.source = Qt.resolvedUrl("images/04.Notes_Screen.png")
                detailPage.currentDetailId = "04.Notes"
            } else if (detailPage.currentDetailId === "04.Notes") {
                dummyImage.source = Qt.resolvedUrl("images/05.Notes_Screen.png")
                detailPage.currentDetailId = "05.Notes"
            } else if (detailPage.currentDetailId === "05.Notes") {
                dummyImage.source = Qt.resolvedUrl("images/01.Grid_cleanup_Screen.png")
                detailPage.currentDetailId = "01.Cleanup"
            } else if (detailPage.currentDetailId === "01.Cleanup") {
                dummyImage.source = Qt.resolvedUrl("images/02.Grid_cleanup_Screen.png")
                detailPage.currentDetailId = "02.Cleanup"
            } else if (detailPage.currentDetailId === "02.Cleanup") {
                dummyImage.source = Qt.resolvedUrl("images/02.Grid_groups_Screen.png")
                detailPage.currentDetailId = "02.Groups"
            } else if (detailPage.currentDetailId === "01.Groups") {
                dummyImage.source = Qt.resolvedUrl("images/02.Grid_groups_Screen.png")
                detailPage.currentDetailId = "02.Groups"
            } else if (detailPage.currentDetailId === "02.Groups") {
                dummyImage.source = Qt.resolvedUrl("images/03.Grid_groups_Screen.png")
                detailPage.currentDetailId = "03.Groups"
            } else if (detailPage.currentDetailId === "03.Groups") {
                dummyImage.source = Qt.resolvedUrl("images/02.Notes_Screen.png")
                detailPage.currentDetailId = "02.Notes"
            }
        }
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

//            TextEdit {
//                id: notePad
//                width: parent.width
//                height: 850
//                textFormat: TextEdit.AutoText
////                Layout.fillWidth: true
////                textFormat: TextEdit.MarkdownText
//            }
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

                title.text = currentTitle !== undefined ? currentTitle : message.title

                if (message.html !== undefined) {
                    var html = message.html.replace("<h1>", "<strong>")
                    html = html.replace("</h1>", "</strong>")
                    html = html.replace(/((<p>){2,})/g, "<p>")
                    html = html.replace(/((<\/p>){2,})/g, "</p>")
//                    console.log("DetailPage | html: " + html)

                    text.text = html
                }

                if (message.imageUrl !== undefined) {
                    image.source = message.imageUrl
                }

                author.text = currentDetailAuthorAndDate
            }
        }
    }

    // @disable-check M300
    AN.Share {
        id: an
    }
}
