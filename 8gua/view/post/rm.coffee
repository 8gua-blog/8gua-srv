fs = require 'fs-extra'
path = require 'path'

TMP = ".tmp"

name_unique = (tofile)->
    count = 1
    file = tofile
    while 1
        if not fs.pathExistsSync(file)
            break
        filename = path.basename(tofile).split(".")
        filename = filename.shift()+"."+count+"."+filename.join('.')
        file = path.join(
            path.dirname(tofile),
            filename
        )
        count += 1
    return file

module.exports =  (req, reply)=>
    {hostpath} = req
    prefix = path.join(hostpath, "-/md")
    file = req.params['*']
    filepath = path.join(prefix, file)
    if file.slice(0,8) == "!/trash/"
        console.log file
    else
        tofile = name_unique(path.join(prefix, "!/trash", file))
        await fs.mkdirp(path.dirname(tofile))
        tmppath = filepath+TMP
        await fs.move(filepath, tofile,  { overwrite: true })
        if await fs.pathExists(tmppath)
            await fs.move(tmppath, tofile+TMP,  { overwrite: true })
    reply.send {}
