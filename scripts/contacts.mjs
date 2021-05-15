WorkerScript.onMessage = function(message) {
    var contactsStr = message.contactsStr
    var contacts = contactsStr.length === 0 ? new Array : JSON.parse(contactsStr)
    WorkerScript.sendMessage({ 'contacts': contacts })
}
