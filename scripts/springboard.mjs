WorkerScript.onMessage = function(message) {
    console.log("Springboard | Will execute worker script")

    var selectedObj = message.selectedObj
    var textInput = message.textInput
    var contacts = message.contacts
    var model = message.model
    var actionType = message.actionType
    var actionName = message.actionName

    function phoneNumberForContact() {
        var phoneNumber = -1
        if (selectedObj !== undefined) {
            // todo: offer selection of phone numbers
            if (selectedObj["phone.mobile"] !== undefined && selectedObj["phone.mobile"].length > 0) {
                phoneNumber = selectedObj["phone.mobile"]
            } else if (selectedObj["phone.home"] !== undefined && selectedObj["phone.home"].length > 0) {
                phoneNumber = selectedObj["phone.home"]
            } else if (selectedObj["phone.work"] !== undefined && selectedObj["phone.work"].length > 0) {
                phoneNumber = selectedObj["phone.work"]
            } else if (selectedObj["phone.other"] !== undefined && selectedObj["phone.other"].length > 0) {
                phoneNumber = selectedObj["phone.other"]
            } else {
                toast = qsTr("Sorry. I couldn't find a phone number for this contact")
            }
        } else {
            toast = qsTr("Sorry. I couldn't identify the contact")
        }

        return phoneNumber
    }

    function emailAddressForContact() {
        var emailAddress
        if (selectedObj) {
            console.log("Springboard | Contact " + selectedObj["id"] + " " + selectedObj["name"])
            // todo: offer selection of email address
            if (selectedObj["email.home"].length > 0) {
                emailAddress = selectedObj["email.home"]
            } else if (selectedObj["email.work"].length > 0) {
                emailAddress = selectedObj["email.work"]
            } else if (selectedObj["email.mobile"].length > 0) {
                emailAddress = selectedObj["email.mobile"]
            }
        } else {
            toast = qsTr("Sorry. I couldn't identify the contact")
        }

        return emailAddress
    }

    function textInputHasMultiTokens() {
        return /\S+\s\S+/.test(textInput)
    }

    function textInputHasMultiLines() {
        return /\n/.test(textInput)
    }

    function textInputHasContactPrefix() {
        return textInput.indexOf("@") === 0
    }

    function textInputStartsWithPhoneNumber() {
        return /^\+?\d{4,}(\s\S+)?/.test(textInput)
    }

    function textInputStartWithEmailAddress() {
        return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}\s\S+/.test(textInput)
    }

    function textInputIsWebAddress() {
        var urlregex = /^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$/
        return urlregex.test(textInput.trim());
    }

    function textInputCouldBeRssFeed() {
        return textInput.indexOf("http") == 0 ? textInput.lastIndexOf("/") > 7 : textInput.lastIndexOf("/") > 3
    }

    var filteredSuggestionObj = new Array
    var filteredSuggestion
    var suggestion
    var found
    var i

    if (textInputHasMultiTokens()) {
        if (textInputHasContactPrefix()) {
            filteredSuggestionObj[0] = [actionName.SendSMS, actionType.SendSMS]
            filteredSuggestionObj[1] = [actionName.SendEmail, actionType.SendEmail]
        } else if (textInputStartsWithPhoneNumber()) {
            filteredSuggestionObj[0] = [actionName.SendSMS, actionType.SendSMS]
        } else if (textInputStartWithEmailAddress()) {
            filteredSuggestionObj[0] = [actionName.SendEmail, actionType.SendEmail]
        } else if (textInputHasMultiLines()) {
            filteredSuggestionObj[0] = [actionName.CreateNote, actionType.CreateNote]
        } else {
            filteredSuggestionObj[0] = [actionName.CreateNote, actionType.CreateNote]
            filteredSuggestionObj[1] = [actionName.SearchWeb, actionType.SearchWeb]
        }
    } else if (textInputHasContactPrefix()) {
        var lastChar = textInput.substring(textInput.length - 1, textInput.length)
        console.log("Springboard | last char: " + lastChar)
        if (lastChar === " ") {
            filteredSuggestionObj[0] = [actionName.MakeCall, actionType.MakeCall]
        }

        var lastToken = textInput.substring(1, textInput.length).toLowerCase()
        console.log("Springboard | last token:" + lastToken)
        for (i = 0; i < contacts.length; i++) {
            var contact = contacts[i]
            var name = contact["name"].toLowerCase()
            if (lastToken.length === 0 || name.includes(lastToken)) {
                filteredSuggestionObj[i] = [contact["name"], actionType.SuggestContact, contact]
            }
        }
    } else if (textInputIsWebAddress()) {
        filteredSuggestionObj[0] = [actionName.OpenURL, actionType.OpenURL]
        if (textInputCouldBeRssFeed()) {
            filteredSuggestionObj[1] = [actionName.AddFeed, actionType.AddFeed]
        }
    } else if (textInputStartsWithPhoneNumber()) {
        filteredSuggestionObj[0] = [actionName.MakeCall, actionType.MakeCall]
    } else if (textInput.length > 1) {
        filteredSuggestionObj[0] = [actionName.SearchWeb, actionType.SearchWeb]
    } else if (defaultSuggestions) {
        filteredSuggestionObj[0] = [qsTr("Make Call"), actionType.MakeCall]
        filteredSuggestionObj[1] = [qsTr("Create Message"), actionType.SendSMS]
        filteredSuggestionObj[2] = [qsTr("Create Mail"), actionType.SendEmail]
        filteredSuggestionObj[3] = [qsTr("Open Cam"), actionType.OpenCam]
        filteredSuggestionObj[4] = [qsTr("Gallery"), actionType.ShowGallery]
        filteredSuggestionObj[5] = [qsTr("Recent people"), actionType.ShowContacts]
        filteredSuggestionObj[6] = [qsTr("Recent threads"), actionType.ShowThreads]
        filteredSuggestionObj[7] = [qsTr("Recent news"), actionType.ShowNews]
    }

    var existingSuggestionObj = new Object
    for (i = 0; i < model.count; ++i) {
        suggestion = model.get(i).text
        existingSuggestionObj[suggestion] = true
    }

    // remove items no longer in filtered set
    i = 0
    while (i < model.count) {
        suggestion = model.get(i).text
        found = filteredSuggestionObj.hasOwnProperty(suggestion)
        if (!found) {
            model.remove(i)
        } else {
            i++
        }
    }

    // add new items
    filteredSuggestionObj.forEach(function (item, index) {
        found = existingSuggestionObj.hasOwnProperty(item)
        if (!found) {
            // for simplicity, just adding to end instead of corresponding position in original list
            model.append({ "text": item[0], "action": item[1], "object": item[2] })
        }
        console.log("Springboard | Append Suggestion: " + item[0])
    });

    model.sync()

    WorkerScript.sendMessage({ })
}


