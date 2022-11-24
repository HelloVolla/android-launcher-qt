import Socket 1.0

Socket {
    id: signald
    property var socketStateNames: [
        "DisconnectedState",
        "ConnectingState",
        "ConnectedState",
        "DisconnectingState"
    ]

    readonly property string signalProductionServerId: "6e2eb5a8-5706-45d0-8377-127a816411a4"
    readonly property string signalStagingServerId: "97c17f0c-e53b-426f-8ffa-c052d4183f83"
    property string signalServerId: signalProductionServerId
    // property string signalAccountType: 'primary'
    property string signalPhoneNumber: ""
    property string signaldProtocolVersion: "v1"
    property string signaldDeviceName: "Volla Launcher"

    property bool isConnectedToSignald: state === 2
    property var linkedAccounts: []
    property bool isListening: false

    property var versionData
    property var pendingRequests: ({
                                       // requestId: callback
                                   })

    signal clientMessageReceived(string message)

    onStateChanged: console.log("Signald connection state: ", socketStateNames[state])

    onConnected: {
        console.log("Connected to signald")
        version(function(error, response){
            versionData = response
        })

        list_accounts(function(error, response){
            if(!error) {
                linkedAccounts = response.accounts
            }
        })
    }

    onDisconnected: {
        console.log("Disconnected from signald")
        versionData = null
        linkedAccounts = []
        // pendingRequests = {}
    }

    onRead: {
        let submessages = message.split('\n')

        for (let submessage of submessages) {
            if (submessage.trim().length === 0)
                continue;
            var response
            try {
                response = JSON.parse(submessage)
            } catch (e) {
                console.error(e)
                console.error("unable to parse message: ", submessage)
            }
            let callback = pendingRequests[response["id"]]
            let error = response.error

            if (error) {
                error['error_type'] = response['error_type']
            }

            if (typeof callback === 'function') {
                callback(response.error, response.data)
            } else {
                clientMessageReceived(submessage)
            }
        }
    }

    function sendRequest(request, callback) {
        let requestId = uuid()
        request["id"] = requestId
        request["version"] = signaldProtocolVersion
        if (typeof callback === "function") {
            pendingRequests[requestId] = callback
        }
        write(JSON.stringify(request) + "\n")
    }

    function generate_linking_uri(callback) {
        // linking to an existing account is also possible
        sendRequest({
                        "type": "generate_linking_uri",
                        "server": signalServerId
                    },
                    callback)
        //print("Make this a QR code and scan it on your primary signal device:", resp.uri)
        //await signald.finish_link(device_name="friendly-device-name", session_id=resp.session_id)
    }

    // Not my fav. api because of boolean parameter but this should do for now
    function finish_link(sessionId, overwrite, callback) {
        sendRequest({
                        "type": "finish_link",
                        "device_name": signaldDeviceName,
                        "session_id": sessionId,
                        "overwrite": overwrite
                    },
                    callback)
    }

    function list_accounts(callback) {
        sendRequest({
                        "type": "list_accounts"
                    },
                    callback)
    }

    function list_contacts(account, async, callback) {
        sendRequest({
                        "type": "list_contacts",
                        "account": account,
                        "async": async || false
                    },
                    callback)
    }

    function version(callback) {
        sendRequest({
                        "type": "version"
                    },
                    callback)
    }

    function subscribe(account, callback) {
        sendRequest({
                        "type": "subscribe",
                        "account": account
                    },
                    callback)
    }

    function unsubscribe(account, callback) {
        sendRequest({
                        "type": "unsubscribe",
                        "account": account
                    },
                    callback)
    }

    function request_sync(account, options, callback) {
        options = options || {};
        sendRequest({
                        "type": "request_sync",
                        "account": account,
                        "blocked": options["blocked"] || true,
                        "configuration": options["configuration"] || true,
                        "contacts": options["contacts"] || true,
                        "groups": options["groups"] || true,
                        "keys": options["keys"] || true
                    },
                    callback)
    }

    /*
    // https://signald.org/protocol/actions/v1/send/
    {
        "account": "0cc10e61-d64c-4dbc-b51c-334f7dd45a4a",
        "members": [
            {
                "number": "+13215551234"
            }
        ],
        "mentions": [
            {
                "length": 1,
                "start": 4,
                "uuid": "aeed01f0-a234-478e-8cf7-261c283151e7"
            }
        ],
        "messageBody": "hello",
        "quote": {
            "author": {
                "number": "+13215551234"
            },
            "id": 1615576442475,
            "mentions": [
                {
                    "length": 1,
                    "start": 4,
                    "uuid": "aeed01f0-a234-478e-8cf7-261c283151e7"
                }
            ],
            "text": "hey ? what's up?"
        },
        "recipientAddress": {
            "number": "+13215551234"
        },
        "recipientGroupId": "EdSqI90cS0UomDpgUXOlCoObWvQOXlH5G3Z2d3f4ayE=",
        "type": "send",
        "username": "+12024561414",
        "version": "v1"
    }
    */
    function sendMessage(account, recipientAddressNumber, messageBody,  callback) {
        sendRequest({
                        "type": "send",
                        "account": account,
                        "messageBody": messageBody,
                        "recipientAddress": {
                            "number": recipientAddressNumber
                        }
                    },
                    callback)
    }
}
