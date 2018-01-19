fs = require 'fs-extra'
path = require 'path'
module.exports = (cwd, git_template, argv)->
    await require('./host-path')(cwd)
    await require('./get.coffee')(git_template, cwd, argv.force)
