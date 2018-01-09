fs = require 'fs-extra'
path = require 'path'


module.exports = (req, reply)=>
    {hostpath, body} = req
    console.log body
    reply.send 0
