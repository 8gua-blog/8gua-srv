fs = require 'fs-extra'
path = require 'path'
md_dir = require("8gua/util/md_dir")

module.exports = (req, reply)=>
    {hostpath, body} = req
    await md_dir.sort_summary(hostpath, body)
    reply.send 0
