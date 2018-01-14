md_dir = require("8gua/util/md_dir")
path = require 'path'


module.exports = (req, reply)=>
    {hostpath, body} = req
    dir = body.shift()
    await md_dir.sort_md(hostpath, dir, body)
    reply.send 0
