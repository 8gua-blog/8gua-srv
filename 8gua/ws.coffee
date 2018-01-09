toml_config = require("8gua/lib/toml_config_8gua")
co = require('co')
https = require('https')
WebSocketServer = require('ws').Server
WS_HOST = require("./ws/host")
#WebSocketServer = require('uws').Server

module.exports = (host, port, ssl_key, ssl_cert)->
    options = {
        key: ssl_key
        cert: ssl_cert
    }

    httpsServer = https.createServer(
        options
    )
    httpsServer.listen(port)

    wss = new WebSocketServer {
        server: httpsServer
    }
    console.log("websocket SERVER PORT wss://#{host}:#{port}")

    ws_li = []
    wss.on 'connection', ->
        WS_HOST.connection.apply WS_HOST, arguments
            # wslog ws, message
            # try
            #     recv ws, message
            # catch error
            # console.error "X", message, error

# _err_exit = (err) ->
#     console.error('ERROR EXIT', err.stack)
#     try
#         killtimer = setTimeout(
#             ->
#                 process.exit(1)
#             1000
#         )
#         killtimer.unref()
#     catch e
#         console.log('error when exit', e.stack)

# process.on(
#     'uncaughtException'
#     _err_exit
# )
