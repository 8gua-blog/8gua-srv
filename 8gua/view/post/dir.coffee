path = require 'path'
toml_config = require "8gua/lib/toml_config"
Git = require '8gua/util/git'
fs = require 'fs-extra'
md_dir = require("8gua/util/md_dir")
glob_md = require('8gua/util/glob_md')

DIR_MD = "md"
module.exports =  {
    get:({hostpath}, reply)=>
        r = []
        for li in (await md_dir.li(path.join(hostpath, DIR_MD)))
            r.push(li.join("\r"))
        reply.send(
            r.join("\n")
        )


    post:({body, hostpath}, reply)=>
        {name, dir, old, sort} = body
        name = name.trim()
        dir = dir.trim().toLowerCase()
        err = {}
        if not name
            err.name = "请输入章节名称"
        if not dir
            err.dir = "请输入网址路径"
        else if not /^[a-z0-9-]+$/.test(dir)
            err.dir = "路径只能包含 英文、数字或减号"
        raise err
        prefix = path.join(hostpath, DIR_MD)
        dirpath = path.join(prefix, dir)
        git = Git(hostpath)
        if old
            oldpath = path.join(prefix, old)
        if old and await fs.pathExists(oldpath)
            if oldpath != dirpath
                if await fs.pathExists(dirpath)
                    err.dir = "路径 #{dir} 已存在，请先改名"
                    raise err
                else
                    await fs.move(oldpath, dirpath, { overwrite: true })
                    git.sync(dirpath)
                    for i in [old, dir]
                        await fs.remove(
                            path.join(hostpath,"-", i)
                        )
                    link_dir = path.join(hostpath,"-", dir)
                    await fs.mkdirp(link_dir)
                    for [file] in await glob_md(dirpath)
                        link_file = path.join(
                                link_dir,
                                path.basename(file)
                            )
                        await fs.symlink(
                            path.relative(
                                link_dir
                                file
                            ),
                            link_file
                        )
                        git.sync(link_file)
            else
                old = ''
        else if not await fs.pathExists(dirpath)
            await fs.mkdirp(dirpath)

        init_toml = toml_config(path.join(dirpath,"init.toml"))
        init_toml.set("sort", sort-0)
        if old
            md_dir.dir.rename(
                hostpath
                dir
                name
                old
            )
        else
            md_dir.dir.set(
                hostpath
                dir
                name
            )
        reply.send({})
}
