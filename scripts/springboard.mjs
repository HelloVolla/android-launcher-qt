WorkerScript.onMessage = function(message) {
    console.log("Springboard | Will execute main worker script")

    var selectedObj = message.selectedObj
    var textInput = message.textInput
    var contacts = message.contacts
    var model = message.model
    var actionType = message.actionType
    var actionName = message.actionName   
    var eventRegex = message.eventRegex

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
        return textInput.indexOf("http") === 0 ? textInput.lastIndexOf("/") > 7 : textInput.lastIndexOf("/") > 3
    }

    function textInputCouldBeEvent() {
        // Geman style
        var pattern1 = /^(\d{1,2})\.(\d{1,2})\.(\d{2,4})?\s(\d{1,2}\:?\d{0,2})?-?(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr\s)?(\S.*)/gim

        // US style
        var pattern2 = /^(\d{2,4})\/(\d{1,2})\/(\d{1,2})?\s(\d{1,2}\:?\d{0,2})?-?(\d{1,2}\:?\d{0,2})?\s?(am|pm|uhr\s)?(\S.*)/gim
        console.log("Springboard | Regex: " + eventRegex)
        return pattern1.test(textInput.trim()) || pattern2.test(textInput.trim()) || eventRegex.test(textInput.trim())
    }

    function textInputCouldBeNewContact() {
        return /([0-9a-zäüöA-Z-ÄÜÖß]+)(\s[0-9a-zäüöA-Z-ÄÜÖß]+)?\s(\+?[\d\s]+)/.test(textInput)
    }

    var filteredSuggestionObj = new Array
    var indexOfFirstSuggestion = 0
    var suggestion
    var found
    var i

    if (textInputHasMultiTokens()) {
        if (textInputHasContactPrefix()) {
            if (selectedObj !== undefined) {
                if (selectedObj["phone.mobile"] !== undefined && selectedObj["phone.mobile"].length > 0) {
                    filteredSuggestionObj.push([actionName.SendSMS, actionType.SendSMS])
                }
                if (selectedObj["phone.signal"] !== undefined && selectedObj["phone.signal"].length > 0) {
                    filteredSuggestionObj.push([actionName.SendSignal, actionType.SendSignal])
                }
                var emailAddressCount = 0
                if (selectedObj["email.home"] !== undefined && selectedObj["email.home"].length > 0) {
                    emailAddressCount++
                    filteredSuggestionObj.push([actionName.SendEmailToHome, actionType.SendEmailToHome])
                }
                if (selectedObj["email.work"] !== undefined && selectedObj["email.work"].length > 0) {
                    emailAddressCount++
                    filteredSuggestionObj.push([actionName.SendEmailToWork, actionType.SendEmailToWork])
                }
                if (selectedObj["email.other"] !== undefined && selectedObj["email.other"].length > 0) {
                    filteredSuggestionObj.push([emailAddressCount === 0 ? actionName.SendEmail : actionName.SendEmailToOther, actionType.SendEmailToOther])
                }
            } else {
                console.log("Springboard | Missing selected object")
            }
        } else if (textInputStartsWithPhoneNumber()) {
            filteredSuggestionObj[0] = [actionName.SendSMS, actionType.SendSMS]
        } else if (textInputStartWithEmailAddress()) {
            filteredSuggestionObj[0] = [actionName.SendEmail, actionType.SendEmail]
        } else if (textInputCouldBeEvent()) {
            filteredSuggestionObj[0] = [actionName.CreateEvent, actionType.CreateEvent]
            filteredSuggestionObj[1] = [actionName.CreateNote, actionType.CreateNote]
        } else if (textInputHasMultiLines()) {
            filteredSuggestionObj[0] = [actionName.CreateNote, actionType.CreateNote]
        } else {
            filteredSuggestionObj[0] = [actionName.SearchWeb, actionType.SearchWeb]
            filteredSuggestionObj[1] = [actionName.CreateNote, actionType.CreateNote]
        }
    } else if (textInputHasContactPrefix()) {
        var lastChar = textInput.substring(textInput.length - 1, textInput.length)
        console.log("Springboard | last char: " + lastChar)
        if (lastChar === " ") {
            if (selectedObj !== undefined) {
                var phoneNumberCount = 0
                if (selectedObj["phone.mobile"] !== undefined && selectedObj["phone.mobile"].length > 0) {
                    phoneNumberCount++
                    filteredSuggestionObj.push([actionName.MakeCallToMobile, actionType.MakeCallToMobile])
                }
                if (selectedObj["phone.home"] !== undefined && selectedObj["phone.home"].length > 0) {
                    phoneNumberCount++
                    filteredSuggestionObj.push([actionName.MakeCallToHome, actionType.MakeCallToHome])
                }
                if (selectedObj["phone.work"] !== undefined && selectedObj["phone.work"].length > 0) {
                    phoneNumberCount++
                    filteredSuggestionObj.push([actionName.MakeCallToWork, actionType.MakeCallToWork])
                }
                if (selectedObj["phone.other"] !== undefined && selectedObj["phone.other"].length > 0) {
                    filteredSuggestionObj.push([phoneNumberCount === 0 ? actionName.MakeCall : actionName.MakeCallToOther, actionType.MakeCallToOther])
                }
                if (selectedObj["phone.signal"] !== undefined && selectedObj["phone.signal"].length > 0) {
                    filteredSuggestionObj.push([actionName.OpenSignalContact, actionType.OpenSignalContact])
                }
            } else {
                console.log("SpringBoard | No contact selected")
            }
        } else {
            var lastToken = textInput.substring(1, textInput.length).toLowerCase()
            for (i = 0; i < contacts.length; i++) {
                var contact = contacts[i]
                var name = contact["name"].toLowerCase()
                if (lastToken.length === 0 || name.includes(lastToken)) {
                    filteredSuggestionObj[i] = [contact["name"], actionType.SuggestContact, JSON.parse(JSON.stringify(contact))]
                }
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
        indexOfFirstSuggestion = 1
        lastToken = textInput.substring(0, textInput.length).toLowerCase()
        for (i = 0; i < contacts.length; i++) {
            contact = contacts[i]
            name = contact["name"].toLowerCase()
            if (lastToken.length === 0 || name.includes(lastToken)) {
                filteredSuggestionObj[i+1] = [contact["name"], actionType.SuggestContact, JSON.parse(JSON.stringify(contact))]
            }
        }
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
            model.append({ "text": item[0], "action": item[1], "actionObj": item[2] })
        }
        console.debug("Springboard | Append Suggestion: " + item[0])
    });

    model.sync()

    WorkerScript.sendMessage( {'indexOfFirstSuggestion': indexOfFirstSuggestion } )
}

