md_dir = require("8gua/util/md_dir")
git = require '8gua/util/git'
{trim} = require('lodash')
fs = require 'fs-extra'
path = require 'path'

DIR = "-/md/~"
module.exports = {
    post:(req, reply)=>
        {hostpath} = req
        {url, show} = req.body
        url = trim(url.trim().toLowerCase(),"/")
        show = show - 0
        err = {}
        if not url
            err.url = "请输入网址路径"
        else if not /^[a-z0-9-\/]+$/.test(url)
            err.url = "路径只能包含 英文、数字、减号或斜杠"
        else
            mdfile = url+".md"
            li = [
                hostpath
                DIR
                mdfile
            ]
            filepath = path.join(...li)
            if await fs.pathExists(filepath)
                dir = path.join(...li[0..1])
                if show
                    md = await fs.readFile(filepath)
                    await md_dir.add_url(
                        dir
                        mdfile
                        md_dir.md_h1(md)
                    )
                else
                    await md_dir.rm_url(dir, mdfile)
            else
                md = ""
        raise err

        li.splice(2, 0, ".menu")
        showpath = path.join(...li)
        if await fs.pathExists(showpath)
            if not show
                await fs.remove(showpath)
        else if show
            await fs.ensureFile(showpath)
        git(hostpath).sync(path.join(...li[1..]))

        reply.send [url, md]

    get: (req, reply)=>
        reply.send 0
}
