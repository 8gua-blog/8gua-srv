fs = require 'fs-extra'
path = require 'path'
git = require '8gua/util/git'


module.exports = (hostpath, file, body, commit=true)=>
    filepath = path.resolve(path.join(hostpath, file))
    if filepath.indexOf(hostpath) != 0
        return
    if body
        await fs.mkdirp(path.dirname(filepath))

        await fs.writeFile(
            filepath
            body
        )
    else
        await fs.remove filepath
    if commit
        git(hostpath).sync file
    return
