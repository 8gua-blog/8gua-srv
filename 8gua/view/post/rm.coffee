md_dir = require("8gua/util/md_dir")
Git = require '8gua/util/git'
glob_md = require('8gua/util/glob_md')
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

md_count = (hostpath, dir)->
    dirpath = path.join(hostpath, "md",  dir)
    stat = await fs.lstat(dirpath)
    if stat.isDirectory()
        return (await glob_md(dirpath)).length
    return 0

module.exports =  {
    get : ({hostpath, params}, reply)=>
        reply.send(
            await md_count(hostpath, params['*'])
        )

    post : (req, reply)=>
        {hostpath} = req
        prefix = path.join(hostpath, "md")
        file = req.params['*']
        filepath = path.join(prefix, file)
        if file.startsWith "$/.trash"
            console.log file
        else
            is_exist = await fs.pathExists(filepath)
            if is_exist
                stat = await fs.lstat(filepath)
                is_dir = stat.isDirectory()
            else
                is_dir = 0
            rm = 1
            if is_dir
                if not (await glob_md(filepath)).length
                    await fs.remove(filepath)
                else
                    rm = 0
            else
                tofile = name_unique(
                    path.join(
                        prefix,
                        "$/.trash",
                        file
                    )
                )
                await fs.mkdirp(path.dirname(tofile))
                tmppath = filepath+TMP
                if is_exist
                    await fs.move(filepath, tofile,  { overwrite: true })
                if await fs.pathExists(tmppath)
                    await fs.move(
                        tmppath
                        tofile+TMP
                        { overwrite: true }
                    )
            if rm
                git = Git(hostpath)
                if file.startsWith("!/")
                    await md_dir.rm_url(
                        hostpath
                        file.slice(2)
                    )
                else
                    await md_dir.rm(hostpath, file)
                git.sync()
        reply.send {}
}
