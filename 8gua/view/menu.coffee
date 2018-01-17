save = require('8gua/util/save')
md_dir = require("8gua/util/md_dir")
git = require '8gua/util/git'
{trim} = require('lodash')
{move_autoname} = require('8gua/util/fs')
fs = require 'fs-extra'
path = require 'path'

DIR_MD = "-/md"
DIR = "-/md/~"


module.exports = {
    post:(req, reply)=>
        {hostpath} = req
        {url, show, old} = req.body
        show = show - 0
        li = [
            hostpath
            DIR
        ]
        dir = path.join(...li)
        if show < 0
            if old.startsWith("$/")
                url = old
            else
                url = await move_autoname(
                    path.join(hostpath, "-/md")
                    "$"
                    old
                )
                await md_dir.rm_url(dir, old)
            git(hostpath).sync(path.join(DIR_MD, url))
            url = url.slice(0, -3)
        else
            url = trim(url.trim().toLowerCase(),"/")

            err = {}
            if not url
                err.url = "请输入网址路径"
            else if not /^[a-z0-9-\/]+$/.test(url)
                err.url = "路径只能包含 英文、数字、减号或斜杠"
            raise err

            mdfile = url+".md"
            li.push mdfile
            filepath = path.join(...li)

            if old != "~/"+mdfile
                if await fs.pathExists(filepath)
                    err.url = "路径已被占用，请用新的"
                    raise err
                oldpath = path.join(hostpath, DIR_MD, old)
                if await fs.pathExists(oldpath)
                    await md_dir.rm_url(dir, old.slice(2))
                    await fs.move(oldpath, filepath)
            if await fs.pathExists(filepath)
                if show
                    h1 = md_dir.md_h1(await fs.readFile(filepath,'utf-8'))
                    await md_dir.add_url(
                        dir
                        mdfile
                        h1
                    )
                else
                    await md_dir.rm_url(dir, mdfile)
            git(hostpath).sync(path.join(...li[1..]))

        reply.send [url]

    get: (req, reply)=>
        {hostpath} = req
        li = await md_dir.tree(path.join(hostpath, "-/md/~"))
        li = li.concat(await md_dir.li_md_h1(hostpath, ["$"]))
        reply.send li
}
