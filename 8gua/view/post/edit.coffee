fs = require 'fs-extra'
glob = require "glob-promise"
path = require 'path'
{isEmpty} = require("lodash")

glob_md = require('8gua/util/glob_md')

module.exports = {
    get : (req, reply)=>
        {hostpath} = req
        prefix = path.join(hostpath, '-/md')
        file = req.params['*']
        # file 为空是首页点击，file 为 / 为侧栏新建，逻辑不太一样
        if not file or file == '/'
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
                    file = file.slice(hostpath.length+6)
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
