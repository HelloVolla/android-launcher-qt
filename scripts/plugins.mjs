WorkerScript.onMessage = function(message) {
    var selectedObj = message.selectedObj
    var textInput = message.textInput
    var contacts = message.contacts
    var model = message.model
    var actionType = message.actionType
    var plugins = message.plugins

    var pluginFunctions = new Array
    var autocompletions = new Array
    var i

    for (i = 0; i < plugins.length; i++) {
        console.debug("Plugin script | " + plugins[i].id)
        var result = plugins[i].processInput(textInput)
        if (result["function"] === undefined) {
            pluginFunctions.push({
                 "text": result["label"],
                 "action": actionType.ExecutePlugin,
                 "pluginFunction": result["function"],
                 "isFirstSuggestion": false
            })
        } else {
            autocompletions.push({
                "text": result["label"],
                "act ion": actionType.SuggestPluginEntity,
                "object": result["object"] === undefined ? new Object : result["object"],
                "isFirstSuggestion": false
            })
        }
    }

    var indexOfFirstSuggestion = model.findIndex(el => el.isFirstSuggestion !== true)

    for (i = 0; i < pluginFunctions.length; i++) {
        model.insert(indexOfFirstSuggestion > -1 ? indexOfFirstSuggestion : model.count - 1, pluginFunctions[i])
    }

    for (i = 0; i < autocompletions.length; i++) {
        var autocompletion = autocompletions[i]
        autocompletions.isFirstSuggestion = indexOfFirstSuggestion === -1 && i === 0 ? true : false
        model.append(pluginFunctions[i])
    }

    model.sync()

    WorkerScript.sendMessage(new Object)
}
