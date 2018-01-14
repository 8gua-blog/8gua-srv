fs = require 'fs-extra'
toml_config = require "8gua/lib/toml_config"
path = require 'path'
md_dir = require '8gua/util/md_dir'

module.exports = (req, reply)=>
    {hostpath} = req
    dir = req.params['*']
    reply.send await md_dir.sort(hostpath, dir)
