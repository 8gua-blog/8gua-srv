fs = require 'fs-extra'
path = require 'path'
module.exports = (cwd, git_template, argv)->
    await require('./host-path')(cwd)
    if not await fs.pathExists(path.join(cwd,"-S"))
        console.log "监测到当前目录未初始化，开始初始化"
        await require('./get.coffee')(git_template, cwd, argv.force)
