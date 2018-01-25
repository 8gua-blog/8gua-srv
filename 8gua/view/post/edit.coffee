fs = require 'fs-extra'
glob = require "glob-promise"
path = require 'path'
{isEmpty} = require("lodash")

glob_md = require('8gua/util/glob_md')

module.exports = {
    get : (req, reply)=>
        {hostpath} = req
        file = req.params['*']

        if file.charAt(0) == "!" and file.charAt(1) !="/"
            file = "!/"+file.slice(1)


        new_draft = not file or file == '/'

        if new_draft or file.startsWith("$/")
            dir = "-"
        else
            dir = "md"
        prefix = path.join(hostpath, dir)

        # file 为空是首页点击，file 为 / 为侧栏新建，逻辑不太一样
        if new_draft
            draft = "$"
            li = await glob_md(path.join(prefix, draft))
            if file
                begin = li.length
                while 1
                    ++ begin
                    file = path.join(draft, begin+".md")
                    if not (await fs.pathExists(path.join(prefix, file)))
                        reply.send file
                        return
            else
                if li.length
                    file = li[0][0]
                    filepath = path.resolve(file)
                    file = file.slice(prefix.length+1)
                else
                    file = path.join(draft, "1.md")


        filepath = path.join(prefix, file)

        if await fs.pathExists(filepath)
            md = await fs.readFile(filepath, "utf-8")
        else
            md = ""
        r = {
            md
            file
        }
        tmppath = filepath+".tmp"
        if await fs.pathExists(tmppath)
            tmp = await fs.readFile(tmppath, 'utf-8')
            if tmp == md or not tmp
                await fs.remove(tmppath)
            else
                if md
                    r.tmp = tmp
                else
                    r.md = tmp
        reply.send r

}
