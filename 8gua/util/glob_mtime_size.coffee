glob = require "glob-promise"
fs = require 'fs-extra'
path = require 'path'

module.exports = (dir, ignore)->
    new Promise(
        (resolve, reject)->
            li = []
            for i in await glob(dir)
                if ignore
                    if ignore.indexOf(path.basename(i)) >= 0
                        continue
                {mtimeMs, size} = await fs.stat(i)
                if not size
                    await fs.remove(i)
                    continue
                li.push([i, mtimeMs, size])
            li.sort (a,b) ->
                b[1] - a[1]
            resolve li
    )
