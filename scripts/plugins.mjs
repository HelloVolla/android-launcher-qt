WorkerScript.onMessage = function(message) {
    var selectedObj = message.selectedObj
    var textInput = message.textInput
    var contacts = message.contacts
    var model = message.model
    var actionType = message.actionType
    var plugins = plugins

    console.debug("Plugin script | " + textInput)
    console.debug("Plugin script | " + plugins)
    console.debug("Plugin script | " + plugins.length)
    console.debug("Plugin script | " + plugins[0])


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

    var indexOfFirstSuggestion

    for (i = 0; i < model.count; i++) {
        if (model.get(i).isFirstSuggestion) {
            indexOfFirstSuggestion =i
            break
        }
    }

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
