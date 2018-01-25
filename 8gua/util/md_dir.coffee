{startsWith, padStart, trimStart, trimEnd, trim} = require 'lodash'
firstline = require 'firstline'
glob_md = require('8gua/util/glob_md')
toml = require 'toml'
Git = require '8gua/util/git'
ln_fs = require '8gua/util/ln_fs'
toml_config = require "8gua/lib/toml_config"
fs = require 'fs-extra'
path = require 'path'
glob = require "glob-promise"

SUMMARY = "SUMMARY.md"
DIR_MD= "md"

url_by_link = (line)->
    en = line.slice(line.indexOf('](')+2)
    return en.slice(0, en.lastIndexOf(')'))

trim_read = (file)->
    if await fs.pathExists(file)
        txt = await fs.readFile(file, 'utf-8')
        txt = txt.replace(/^[\r\n\s\uFEFF\xA0]+|[\r\n\s\uFEFF\xA0]+$/g, '')
        return txt
    return ''

summary_li = (file)->
    txt = await trim_read(file)
    if txt
        return txt.split("\n")
    return []



summary_import = (hostpath, dir)->
    prefix = path.join(hostpath, DIR_MD)
    dir_li = []
    suffix = "](#{dir})"
    dirpath = suffix.slice(0,-1)+"/"
    for i in await summary_li(path.join(prefix, dir, SUMMARY))
        if i.startsWith("# ")
            dir_li.push("* ["+i.slice(2).trim()+suffix)
        else if i.startsWith("* ")
            dir_li.push " "+i.replace('](',dirpath)

    index = path.join(prefix, SUMMARY)
    index_li = await summary_li(index)
    dir_txt = dir_li.join("\n")
    begin = 0
    exist = 0
    for i, pos in index_li
        if i.startsWith("* ") and i.indexOf(suffix) > 0
            exist = 1
            begin = pos
            index_li[pos] = dir_txt
            ++pos
            while 1
                if pos >= index_li.length
                    break
                if index_li[pos].startsWith("* ")
                    break
                index_li.splice(pos, 1)
            break
    if not exist
        index_li.push dir_txt
    await fs.writeFile(index, index_li.join("\n"))
    return

_sort = (dirpath)->
    init = path.join(dirpath, "init.toml")
    sort = 1
    if await fs.pathExists(init)
        sort = (toml_config(init).read()).sort or sort
    return sort

CACHE = {}
module.exports = md_dir = {
    li_md_h1:(hostpath, dir_list, root=DIR_MD)->
        cache_host = CACHE[hostpath] = CACHE[hostpath] or {}

        li = []

        prefix = path.join(hostpath, root)

        for i in dir_list
            li.push glob_md(path.join(prefix , i))

        file_li = await Promise.all(li)
        #清除不存在的文件
        cache_host_ = {}
        r = []
        for dir,pos in dir_list
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
                li.push([mtimeMs, path.basename(f), title])

                cache_[f] = [mtimeMs, size, title]
            li.sort (a,b) ->
                b[0] - a[0]
            for i in li
                i.shift()
            r.push li
            cache_host_[dir] = cache_

        CACHE[hostpath] = cache_host_
        return r

    sort_summary:(hostpath, li)->
        summary = path.join(hostpath, DIR_MD, SUMMARY)
        txt = (await trim_read(summary))
        if not txt
            return
        txt = txt.split('\n')
        r = []
        t = undefined
        for line in txt
            if line.startsWith('* ')
                t = []
                r.push [line, t]
            else
                if t and not line.charAt(0).trim()
                    t.push line
                else
                    t = undefined
                    r.push line
        num = 0
        pos2txt = {}
        pos_li = []
        old_li = []
        for i,pos in r
            if i instanceof Array
                h1 = i[0]
                en = url_by_link(h1)
                new_pos = li.indexOf(en)
                if new_pos >= 0
                    old_li.push pos
                    pos2txt[pos] = h1+"\n"+i[1].join('\n')
                    pos_li.push([new_pos, pos])

        pos_li.sort(
            (a,b)=>a[0]-b[0]
        )
        for i, pos in old_li
            r[i] = pos2txt[pos_li[pos][1]]

        await fs.writeFile(summary, r.join('\n'))
        return

    sort_md :(hostpath, dir, li)->
        md_path = await path.join(hostpath, DIR_MD, dir, SUMMARY)
        pos_li = []
        en_line = []
        txt_li = await summary_li(md_path)
        for i, pos in txt_li
            if i.startsWith("* [")
                pos_li.push pos
                en_line.push [li.indexOf(url_by_link(i)), i]
        en_line.sort((a,b)->a[0]-b[0])
        for pos, i in pos_li
            txt_li[pos] = en_line[i][1]
        await fs.writeFile(md_path, txt_li.join('\n'))
        summary_import(hostpath, dir)
        return

    sort : (hostpath, dir)->
        await _sort(path.join(hostpath, DIR_MD, dir))

    add : (hostpath, title, file, old)->
        dirname = path.dirname(file)
        dirpath = path.join(hostpath, DIR_MD, dirname)
        summary = path.join(dirpath, SUMMARY)
        basename = path.basename(file)
        li = await summary_li(summary)
        exist = 0
        suffix = "](#{basename})"
        link = "* ["+title+suffix
        if not file.startsWith("$/")
            await ln_fs.ln(hostpath, DIR_MD, file)

            for line, pos in li
                i = trimStart(line)
                if i.indexOf(suffix) > 0 and i.startsWith("* ")
                    exist = 1
                    li[pos] = padStart(link, line.length-i.length, ' ')

            if not exist
                sort = parseInt(await _sort(dirpath)-0)
                if sort > 0
                    li.push link
                else
                    pushed = 0
                    for i, pos in li
                        if i.startsWith( "# ")
                            li.splice(pos+1, 0, link)
                            pushed = 1
                            break
                    if not pushed
                        li.push link
            await fs.writeFile(summary, li.join("\n"))
            await summary_import(hostpath, dirname)


        if old and not old.startsWith("$/")
            await ln_fs.rm(hostpath, path.join(DIR_MD, old))

            dirname = path.dirname(old)
            oldpath = path.join(hostpath, DIR_MD, dirname, SUMMARY)
            li = await summary_li(oldpath)

            if li.length
                r = []
                for line in li
                    i = line.trim()
                    if i.indexOf(suffix) > 0 and i.startsWith("* ")
                        continue
                    else
                        r.push line
                await fs.writeFile(oldpath, r.join('\n'))
                await summary_import(hostpath, dirname)
        # TODO 重新生成目录
        return ''

    dir : {
        rename:(hostpath, dir, name, old)->
            index = path.join(hostpath, DIR_MD, SUMMARY)
            li = (await fs.readFile(index,"utf-8")).split("\n")
            now = "](#{dir}/"
            pre = "](#{old}/"
            for i,pos in li
                i = trimEnd(i)
                if i.endsWith("](#{old})") and i.startsWith("* [")
                    li[pos] = """* [#{name}](#{dir})"""
                else
                    line = trimStart(i)
                    if line.startsWith("* [") and line.indexOf(pre)>0
                        li[pos] = i.replace(pre, now)
            await fs.writeFile(index, li.join("\n"))
            dir_summary = path.join(hostpath, DIR_MD, dir, SUMMARY)
            li = await summary_li(dir_summary)
            if li.length
                for i,pos in li
                    if i.startsWith("# ")
                        li[pos] = "# "+name
            await fs.writeFile(dir_summary, li.join("\n"))

        set:(hostpath, dir, name)->
            dir_md = path.join(DIR_MD, dir)
            dir_path = path.join(hostpath, dir_md)
            if not await fs.pathExists(dir_path)
                await fs.mkdirp(dir_path)
            summary = path.join(dir_path, SUMMARY)
            title = "# "+name
            li = await summary_li(summary)
            if li.length
                for i,pos in li
                    if i.startsWith("# ")
                        li[pos] = title
                        title = undefined
                        break
                if title
                    li.unshift title
                txt = li.join("\n")
            else
                txt = title
            await fs.writeFile(summary, txt)

            index = path.join(hostpath, DIR_MD, SUMMARY)
            link = "* [#{name}](#{dir})"
            count = 0
            if await fs.pathExists(index)
                li = (await fs.readFile(index, 'utf-8')).split("\n")
                r = []
                for line,pos in li
                    line = trimEnd(line)
                    i = trimStart(line)
                    if i.startsWith('* ') and i.indexOf("](#{dir})") >= 0
                        r.push padStart(link, line.length-i.length, ' ')
                        count += 1
                    else
                        if i or (r.length and r[r.length-1])
                            r.push line
                if not count
                    if r.length
                        last =r.length-1
                        if r[last].trim()
                            r.push link
                        else
                            r[last] = link
                txt = r.join("\n")
            else
                txt = link
            await fs.writeFile(index, txt)
            # tomlpath = path.join(dir_path, "init.toml")

            # if await fs.pathExists(tomlpath)
            #     try
            #         toml = await fs.readFile(tomlpath, "utf-8")
            #         toml = toml_parse toml
            #     catch
            #         toml = {}
            # else
            #     toml = {}
            # toml.NAME = name
            # await fs.writeFile(
            #     tomlpath
            #     tomlify.toToml(toml, {space: 0})
            # )
            git = Git(hostpath)
            git.sync(dir_md)
            git.sync(index)
    }
    rm_url : (hostpath, url)->
        await ln_fs.rm(hostpath, "!"+url)
        summary = path.join(hostpath, DIR_MD, "!", SUMMARY)
        li = []
        for i in await summary_li(summary)
            if i.startsWith("* [") and i.indexOf("](#{url})") > 0
                continue
            li.push i
        await fs.writeFile(summary, li.join("\n"))
        return

    add_url : (hostpath, url, h1)->
        summary = path.join(hostpath, DIR_MD, "!", SUMMARY)
        li = await summary_li(summary)
        txt = "* [#{h1}](#{url})"
        exist = 0
        for i, pos in li
            if i.startsWith("* [") and i.indexOf("](#{url})") > 0
                li[pos] = txt
                exist = 1
        if not exist
            li.push txt
        await ln_fs.ln(
            hostpath
            path.join(DIR_MD,"!")
            url
            "!"
        )
        await fs.writeFile(summary, li.join("\n"))
        return


    rm : (hostpath, file)->
        if file.startsWith('!/')
            return
        dirname = path.dirname(file)
        basename = path.basename(file)
        key = """](#{basename})"""
        summary = path.join(hostpath, DIR_MD, dirname, SUMMARY)
        txt = await fs.readFile(summary, "utf-8")
        r = []
        for line in txt.split("\n")
            line = trimEnd(line)
            i = trimStart(line)
            if i.startsWith("* ")
                if i.indexOf(key) > 0
                    continue
            if i or (r.length and r[r.length-1])
                r.push line
        r = r.join("\n")
        if r != txt
            await fs.writeFile(summary, r)
            await summary_import(hostpath, dirname)
        return

    li_md:(root)->
        txt = await summary_li(path.join(root, SUMMARY))

        dir_li = []

        for i in txt
            if i.startsWith("* [")
                pos =  i.indexOf('](')
                if pos > 0
                    cn = i.slice(i.indexOf("[")+1, pos)
                    en = i.slice(pos+2)
                    en = en.slice(0, en.lastIndexOf(')'))
                    dir_li.push([en, cn])

        return dir_li

    li : (root)->
        dir_li = await md_dir.li_md(root)

        existed = new Set()
        for [en, cn] in dir_li
            existed.add en

        for dir in (await fs.readdir(root))
            if (
                existed.has(dir) or \
                "!$".indexOf(dir.charAt(0)) >= 0 or \
                dir.slice(-3) == ".md"
            )
                continue
            lpath = path.join(root, dir)
            if not (await fs.lstat(lpath)).isDirectory()
                continue
            summary = await fs.readFile(path.join(lpath, SUMMARY), 'utf-8')
            title = md_dir.md_h1(summary)
            if not title
                title = dir

            dir_li.push([dir, title])
        return dir_li
    tree : (dir)->
        dir_len = dir.length+1
        existed = new Set()
        show = []

        for [file, name] in (
            await md_dir.summary_url_li(dir)
        )
            existed.add(file)
            show.push file+" "+name

        no_show = []
        for i in await glob(path.join(dir,"**/*.md"))
            i = i.slice(dir_len)
            if i == SUMMARY or existed.has(i)
                continue
            no_show.push(i)

        return [
            show.join("\n")
            no_show.join("\n")
        ]

    summary_url_li : (dir)->
        file = path.join(dir, SUMMARY)
        r = []
        for i in (await summary_li(file))
            if i.startsWith("* ")
                i = i.slice(2).trim()
                [name, url] = i.split("](")
                r.push([url.slice(0,-1), name.slice(1)])
        return r
    md_h1 : (summary)->
        li = summary.split("\n")
        for i in li
            if i.startsWith("# ")
                return i.slice(1).trim()
        return ''
# 1. 读取 根目录 SUMMARY.md
# 2. 根据 根目录 SUMMARY.md 查找目录
# 3. 录入 SUMMARY.md 中不存在的目录
# 4. 读取每个目录下的 SUMMARY.md 的名称（没有就用根目录的）
        # get: (hostpath)->
        #     prefix = path.join(hostpath,"md/")
        #     li = []
        #     for i in (await fs.readdir(prefix))
        #         init = path.join(prefix, i, 'init.toml')
        #         if await fs.pathExists(init)
        #             o = await fs.readFile init
        #             try
        #                 {NAME} = toml.parse(o)
        #             catch
        #                 NAME = i
        #             li.push([i, NAME])

        #     return li
}
