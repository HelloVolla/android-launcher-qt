WorkerScript.onMessage = function(message) {
    var apps = message.apps
    var labelMap = message.labelMap

    apps.forEach(function(app, i) {
        apps[i].label = app.package in labelMap && app.shortcutId === undefined
                ? qsTr(labelMap[app.package]) : app.label
        apps[i].itemId = app.shortcutId !== undefined ? app.shortcutId : app.package
    })

    apps.sort(function(a, b) {
        if (a.label.toLowerCase() < b.label.toLowerCase())
            return -1;
        if (a.label.toLowerCase() > b.label.toLowerCase())
            return
        return 0
    })

    var model = message.model
    var text = message.text
    var filteredGridDict = new Object
    var filteredGridItem
    var gridItem
    var found
    var i

    // filter model
    for (i = 0; i < apps.length; i++) {
        filteredGridItem = apps[i]
        var modelItemName = apps[i].label
        var modelItemId = apps[i].itemId
        if (text.length === 0 || modelItemName.toLowerCase().includes(text.toLowerCase())) {
            filteredGridDict[modelItemId] = filteredGridItem
        }
    }

    // add new items
    var keys = Object.keys(filteredGridDict)
    keys.forEach(function(key) {
        filteredGridItem = filteredGridDict[key]
        model.append(filteredGridItem)
    })

    model.sync()

    WorkerScript.sendMessage( { 'apps': apps } )
}
