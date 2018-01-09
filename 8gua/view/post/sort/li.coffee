fs = require 'fs-extra'
path = require 'path'


module.exports = (req, reply)=>
    {hostpath, body} = req
    dir = body.pop()
    console.log ">>", dir
    console.log body
    reply.send 0
