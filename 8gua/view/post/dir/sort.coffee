fs = require 'fs-extra'
toml_config = require "8gua/lib/toml_config"
path = require 'path'

module.exports = (req, reply)=>
    {hostpath} = req
    dir = req.params['*']
    init = path.join(hostpath, "-/md", dir, "init.toml")
    console.log init
    sort = 1
    if await fs.pathExists(init)
        sort = (toml_config(init).read()).SORT or sort
    reply.send sort
