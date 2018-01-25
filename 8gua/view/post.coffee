md_dir = require("8gua/util/md_dir")
toml = require 'toml'
Git = require '8gua/util/git'
{move_autoname} = require('8gua/util/fs')
save = require('8gua/util/save')
{trim} = require "lodash"
fs = require 'fs-extra'
path = require 'path'
{isEmpty} = require("lodash")
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

DIR_MD = "md/"
DIR_LI = "$".split ' '
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
                old_file = file
                file = await move_autoname(
                    hostpath
                    if dir == "$" then "-/$" else DIR_MD+dir
                    old_file
                )
        else
            old_file = undefined

        is_draft = file.startsWith("$/")

        tmp = ".tmp"
        if git
            url = file.slice(0, -3)
        else
            url = ''
            if not is_draft
                file = file+tmp


        filepath = (if is_draft then '-/' else DIR_MD)+file
        md = to_markdown(html).trim()
        h1 = h1.trim()

        if h1 or md
            md = "# "+ h1 + "\n" +md

            save hostpath, filepath, md, git

            if git
                if not file.startsWith("!/")
                    await md_dir.add(hostpath, h1, file, old_file)
                if old_file
                    tmppath = path.join(DIR_MD,old_file)
                    await md_dir.rm(hostpath, old_file)
                else
                    tmppath = filepath
                tmppath = path.join(hostpath, tmppath+tmp)
                if await fs.pathExists(tmppath)
                    await fs.remove(tmppath)
        else
            fpath = path.join(hostpath, filepath)
            if await fs.pathExists(fpath)
                await fs.remove(fpath)
            if git
                await md_dir.rm(hostpath, file)
                Git(hostpath).sync()
        reply.send url

    get : ({hostpath}, reply)=>
        dir_li = []
        name_li = []
        r = [name_li, dir_li]

        prefix = path.join(hostpath, DIR_MD)
        for [dir, name] in (await md_dir.li(prefix))
            dir_li.push dir
            name_li.push name
        r = r.concat(await md_dir.li_md_h1(hostpath, DIR_LI, "-"))

        for i in dir_li
            r.push(
                await md_dir.li_md(path.join(hostpath, DIR_MD, i))
            )


        reply.send r
        # file = "md/draft/0.md"
        # filepath = path.resolve(path.join(hostpath, file))
        # if await fs.pathExists(filepath)
        #     body = await fs.readFile(filepath, "utf-8")
        # else
        #     body = ''
        # reply.send {
        #     md:body
        # }
}
