url = require('url')
HOST_PATH = require("8gua/model/hostpath")

class WsHost
    constructor:->
        @_ws = {}

    connection : (ws, req) ->
        _dict = @_ws
        {host} = url.parse(req.headers.origin)

        host_path = HOST_PATH.get(host)
        if not (host_path of _dict)
            _dict[host_path] = []
        li = _dict[host_path]
        li.push(ws)

        rm = ->
            if li.length == 1
                delete _dict[host_path]
            else
                li.splice li.indexOf(ws), 1

        ws.on 'error', (error)->
            rm()

        ws.on 'close', ->
            rm()

    msg:(path, msg)->
        _ws = @_ws
        if path of _ws
            for i in _ws[path]
                i.send "^"+msg

module.exports = new WsHost()

    # rm = ->
    #     ws_li.splice ws_li.indexOf(ws), 1

    # ws.on 'error', (error)->
    #     rm()

    # ws.on 'close', ->
    #     rm()
    #     # user2ws.rm(ws)

    # # user2ws.new(ws)

    # ws.on 'message', (message) ->
    #     ws.send "^"+message
