glob = require "glob-promise"
fs = require 'fs-extra'

module.exports = (path)->
    new Promise(
        (resolve, reject)->
            li = []
            for i in await glob(path)
                {mtimeMs, size} = await fs.stat(i)
                if not size
                    await fs.remove(i)
                    continue
                li.push([i, mtimeMs, size])
            li.sort (a,b) ->
                b[1] - a[1]
            resolve li
    )
