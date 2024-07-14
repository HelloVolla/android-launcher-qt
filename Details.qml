import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Universal 2.12
import QtWebView 1.12
import QtGraphicalEffects 1.12
import AndroidNative 1.0 as AN

LauncherPage {
    id: detailPage
    objectName: "detailPage"
    anchors.fill: parent

    property var currentDetailMode: 0
    property var currentDetailId
    property var currentDetailAuthorAndDate: ""
    property var currentTitle
    property var currentDetailHasBadge: false

    header: Rectangle {
        id: detailPageHeader
        width: parent.width
        height: pinButton.height + 2.5 * mainView.innerSpacing
        z: 2
        color: mainView.backgroundColor
        opacity: mainView.backgroundOpacity === 1.0 ? 1.0 : 0.6
        border.color: "transparent"
        visible: currentDetailMode === mainView.detailMode.Note

        Row {
            id: headerRow
            width: parent.width
            topPadding: mainView.innerSpacing * 2
            leftPadding: mainView.innerSpacing
            rightPadding: mainView.innerSpacing

            Rectangle {
                id: pinBadge
                visible: detailPage.currentDetailHasBadge
                width: mainView.smallFontSize * 0.6
                height: mainView.smallFontSize * 0.6         
                y: (pinButton.height - pinBadge.height) * 0.5
                radius: height * 0.5
                color: mainView.accentColor
                onVisibleChanged: {
                    dateLabel.leftPadding = pinBadge.visible ? 0.8 : 0.0
                }
            }

            Label {
                id: dateLabel
                leftPadding: pinBadge.visible ? 1.0 : 0.0
                width: parent.width - 2 * mainView.innerSpacing - pinButton.width - trashButton.width - pinBadge.width - noteShareButton.width
                height: pinButton.height
                text: detailPage.currentDetailAuthorAndDate
                font.pointSize: mainView.mediumFontSize
                color: mainView.fontColor
                opacity: 0.6
                verticalAlignment: Text.AlignVCenter
            }

            Button {
                id: pinButton
                flat: true
                contentItem: Image {
                    id: pinButtonIcon
                    opacity: 0.6
                    source: Qt.resolvedUrl("/icons/pin@4x.png")
                    fillMode: Image.PreserveAspectFit

                    ColorOverlay {
                        anchors.fill: pinButtonIcon
                        source: pinButtonIcon
                        color: mainView.fontColor
                    }
                }
                background: Rectangle {
                    color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                    border.color: "transparent"
                }
                onClicked: {
                    detailPage.currentDetailHasBadge = !detailPage.currentDetailHasBadge
                    mainView.updateNote(detailPage.currentDetailId,
                                        detailEdit.getText(0, detailEdit.text.length), detailPage.currentDetailHasBadge)
                }
            }

            Button {
                id: trashButton
                flat:true
                contentItem: Image {
                    id: trashButtonIcon
                    source: Qt.resolvedUrl("/icons/trash@4x.png")
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.6

                    ColorOverlay {
                        anchors.fill: trashButtonIcon
                        source: trashButtonIcon
                        color: mainView.fontColor
                    }
                }
                background: Rectangle {
                    color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                    border.color: "transparent"
                }
                onClicked: {
                    mainView.removeNote(detailPage.currentDetailId)
                }
            }

            Button {
                id: noteShareButton
                flat:true
                width: 36.0
                height: 36.0
                bottomPadding: 6.0
                contentItem: Image {
                    id: noteShareButtonIcon
                    source: Qt.resolvedUrl("/icons/share@4x.png")
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.6

                    ColorOverlay {
                        anchors.fill: noteShareButtonIcon
                        source: noteShareButtonIcon
                        color: mainView.fontColor
                    }
                }
                background: Rectangle {
                    color: mainView.backgroundOpacity === 1.0 ? Universal.background : "transparent"
                    border.color: "transparent"
                }
                onClicked: {
                    console.log("Details | Share note")
                    an.shareContent(  {
                        mime_type: 'text/plain',
                        // uri: single_uri
                        text: detailEdit.text.replace(/p, li \{ white-space: pre-wrap; \}/gim, '').replace(/<[^>]+>/g, '').trim()
                        // subject: "This is a sample SUBJECT for sharing"
                        // package: "com.whatsapp"
                    }  )
                }
            }
        }
    }

    function updateDetailPage(mode, id, author, date, title, hasBadge) {
        console.log("DetailPage | Update detail page: " + id + ", " + mode)
        currentDetailMode = mode
        currentDetailId = id !== undefined ? id : Date.now()
        currentDetailAuthorAndDate = author !== undefined ? author  + "\n" + date : date
        currentTitle = title !== undefined ? title : undefined
        currentDetailHasBadge = hasBadge !== undefined ? hasBadge : false
        detailColumn.visible = currentDetailMode === mainView.detailMode.Web
        detailEdit.visible = currentDetailMode === mainView.detailMode.Note
        resetContent()

        switch (mode) {
            case mainView.detailMode.Web:
                prepareWebArticleView(id)
                break
            case mainView.detailMode.Note:
                detailEdit.lastCurserPosition = 0
                prepareNoteView(title, 0)
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
        detailEdit.text = ""
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

    function prepareNoteView(note, curserPosition) {
        console.log("Details | Process note " + currentDetailId + " with curser at " + curserPosition)

        console.debug("================")
        var noteArr = note.split("\n")
        for (var l = 0;l < noteArr.length; l++) console.debug("LINE: " + noteArr[l])

        detailEdit.isBlocked = true
        detailEdit.textLength = note.length

        var styledText = note.slice()
        var urlRegex = /(((https?:\/\/)|([^\s]+\.))[^\s,]+)/g;
        styledText = styledText.replace(urlRegex, function(url,b,c) {
            var url2 = !c.startsWith('http') ?  'http://' + url : url;
            return '<a href="' +url2+ '" target="_blank">' + url + '</a>';
        })

        styledText = styledText.replace(/^(.*$)/gim, '<p>$1</p>')
                               .replace(/<p>(### .*)<\/p>/gim, '<h3><$1</h3>') // h3 tag
                               .replace(/<p>(## .*)<\/p>/gim, '<h2>$1</h2>') // h2 tag
                               .replace(/<p>(# .*)<\/p>/gim, '<h1>$1</h1>') // h1 tag
                               .replace(/<p>(.+)<\/p>/, '<p style=\"font-size:36pt;font-weight:bold\">$1</p>') // trailing text
                               .replace(/(\*\*.+\*\*)/gim, '<b>$1</b>') // bold text
                               .replace(/(\*.+\*)/gim, '<i>$1</i>') // italic text
                               .replace(/<p>(\* .*)<\/p>/gim, '<p style=\"margin-left:12px;text-indent:-12px;\">$1</p>') // unsorted list
                               .replace(/<p>(- .*)<\/p>/gim, '<p style=\"margin-left:12px;text-indent:-12px;\">$1</p>') // unsorted list
                               .replace(/<p>([0-9]+\. .*)<\/p>/gim, '<p style=\"margin-left:20px;text-indent:-20px;\">$1</p>') // ordered list
                               .replace(/^(<p>\s*<\/p>\n)/gim, '')

        if (detailEdit.editMode) {
            styledText = styledText.replace(/^(<p><\/p><p><\/p>$)/gim, '<p>&#8203;</p>')
        }

        console.debug("----------------")
        var textArr = styledText.split("\n")
        for (l = 0;l < textArr.length; l++) console.debug("LINE: " + textArr[l])
        console.debug("================")

        detailEdit.text = styledText

        if (curserPosition !== undefined) {
            detailEdit.cursorPosition = curserPosition
        }

        detailEdit.isBlocked = false

        console.log("Details | Process note finished")
    }

    Flickable {
        id: detailFlickable
        width: parent.width
        height: parent.height
        contentWidth: parent.width
        contentHeight: detailPage.currentDetailMode === mainView.detailMode.Note ? detailEdit.height : detailColumn.height

        //----- news content -----------------

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
                topPadding: mainView.innerSpacing
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
                            uri: currentDetailId,
                            text: currentTitle
                            // subject: "This is a sample SUBJECT for sharing"
                            // package: "com.whatsapp"
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

        //----- note contet -----------------

        function ensureVisible(r) {
            if (contentX >= r.x)
                contentX = r.x;
            else if (contentX+width <= r.x+r.width)
                contentX = r.x+r.width-width;
            if (contentY >= r.y)
                contentY = r.y;
            else if (contentY+height <= r.y+r.height)
                contentY = r.y+r.height-height;
        }

        TextArea {
            id: detailEdit
            width: parent.width
            color: mainView.fontColor
            leftPadding: mainView.innerSpacing
            rightPadding: mainView.innerSpacing
            bottomPadding: mainView.innerSpacing
            font.pointSize: mainView.largeFontSize
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.RichText
            inputMethodHints: Qt.ImhNoPredictiveText
            verticalAlignment: Text.AlignTop
            background: Rectangle {
                color: "transparent"
                border.color: "transparent"
            }

            property bool isBlocked: false
            property bool editMode: false
            property int lastCurserPosition: 0
            property int textLength

            onCursorRectangleChanged: detailFlickable.ensureVisible(cursorRectangle)

            onCursorPositionChanged: {
                editMode = true
                if (detailEdit.isBlocked === false) {
                    console.debug("Details | Curser postion changed from " + lastCurserPosition + " to " + detailEdit.cursorPosition)

                    var plainText = detailEdit.getText(0, 10000)

                    if (plainText.length !== detailEdit.textLength) {
                        mainView.updateNote(detailPage.currentDetailId, plainText, detailPage.currentDetailHasBadge)
                    }

                    detailPage.prepareNoteView(plainText, detailEdit.cursorPosition)
                }
                lastCurserPosition = detailEdit.cursorPosition
            }

            onActiveFocusChanged: {
                console.log("Details | Active focus changed to " + activeFocus)
                if (activeFocus) {
                    detailFlickable.height = mainView.height * 0.46
                } else {
                    var plainText = detailEdit.getText(0, 10000).replace(/[\u200B-\u200D\uFEFF\u200E\u200F]/g, '').trim()
                    mainView.updateNote(detailPage.currentDetailId, plainText, detailPage.currentDetailHasBadge)
                    detailEdit.editMode = false
                    detailEdit.isBlocked = true
                    detailFlickable.height = mainView.height
                }
            }

            onLinkActivated: {
                console.log("Details | Link clicked: " + link)
                Qt.openUrlExternally(link)
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
