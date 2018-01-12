md_dir = require("8gua/util/md_dir")
toml = require 'toml'
{move_autoname} = require('8gua/util/fs')
save = require('8gua/util/save')
{trim} = require "lodash"
fs = require 'fs-extra'
path = require 'path'
{isEmpty} = require("lodash")
firstline = require 'firstline'
glob_md = require('8gua/util/glob_md')
TurndownService = require('turndown')
turndownService = new TurndownService({
    hr:'---'
    headingStyle:"atx"
})
turndownService.use require('turndown-plugin-gfm').gfm

turndownService.addRule('__', {
  filter: ['u','ins']
  replacement: (content) ->
    return '__' + content + '__'
})
turndownService.addRule('```', {
  filter: ['pre']
  replacement: (content) ->
    return '```\n' + content + '\n```'
})

to_markdown = (html)->
    html = html.replace("<br>\n","\n<br>")
    turndownService.turndown(html)

DIR_MD = "-/md/"
DIR_LI = "draft".split ' '
do ->
    for i,pos in DIR_LI
        DIR_LI[pos] = "!/"+i
DIR_LI_LEN = DIR_LI.length
CACHE = {}

module.exports = {
    post: ({hostpath, body}, reply)->
        {html, h1, file, git, dir} = body
        #         if file.charAt(0) == "!"
        #             file = file.slice(2)
        #         console.log file, path.join(
        #             dir
        #             file.slice(file.indexOf('/')+1)
        #         )

        if git != undefined
            git = git - 0
        else
            git = true

        if dir
            if dir+"/" != file.slice(0, dir.length+1)
                git = true
                file = await move_autoname(
                    path.join(hostpath, DIR_MD), dir, file
                )

        tmp = ".tmp"
        if git
            url = file.slice(0, -3)
        else
            url = ''
            if file.slice(0,8) != "!/draft/"
                file = file+tmp
        filepath = DIR_MD+file
        md = to_markdown(html).trim()
        h1 = h1.trim()
        if h1 or md
            md = "# "+ h1 + "\n" +md
            save hostpath, filepath, md, git

            if git
                tmppath = path.join(hostpath, filepath+tmp)
                if await fs.pathExists(tmppath)
                    await fs.remove(tmppath)
        else
            fpath = path.join(hostpath, filepath)
            if not git
                fpath += tmp
            if await fs.pathExists(fpath)
                await fs.remove(fpath)
        reply.send url

    get : ({hostpath}, reply)=>

        cache_host = CACHE[hostpath] = CACHE[hostpath] or {}

        li = []

        prefix = path.join(hostpath, DIR_MD)


        dir_li = []
        name_li = []

        for [dir, name] in (await md_dir.li(prefix))
            dir_li.push dir
            name_li.push name

        dir_li = DIR_LI.concat dir_li
        for i in dir_li
            li.push glob_md(path.join(prefix , i))

        file_li = await Promise.all(li)

        r = [name_li, dir_li.slice(DIR_LI_LEN)]
        #清除不存在的文件
        cache_host_ = {}

        for dir,pos in dir_li
            cache_ = {}
            li = []
            offset = prefix.length + dir.length + 1
            cache = cache_host[dir] or {}
            for [file,mtimeMs, size] in file_li[pos]
                title = undefined

                f = file.slice(offset)
                if f of cache
                    [mtimeMs_, size_, title_] = cache[f]
                    if mtimeMs_ == mtimeMs and size_ == size
                        title = title_

                if title == undefined
                    title = (await firstline(file)).slice(0, 255)

                title = trim(title.trim(), "#").trim()
                if not title
                    title = "无题 "+(new Date(mtimeMs)).toISOString().replace("T"," ").slice(0, 19)
                li.push([mtimeMs, title, path.basename(f)])

                cache_[f] = [mtimeMs, size, title]
            li.sort (a,b) ->
                b[0] - a[0]
            for i in li
                i.shift()
            r.push li
            cache_host_[dir] = cache_

        CACHE[hostpath] = cache_host_

        reply.send r
        # file = "-/md/draft/0.md"
        # filepath = path.resolve(path.join(hostpath, file))
        # if await fs.pathExists(filepath)
        #     body = await fs.readFile(filepath, "utf-8")
        # else
        #     body = ''
        # reply.send {
        #     md:body
        # }
}
