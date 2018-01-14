{startsWith, padStart, trimStart, trimEnd, trim} = require 'lodash'
toml = require 'toml'
Git = require '8gua/util/git'
toml_config = require "8gua/lib/toml_config"
fs = require 'fs-extra'
path = require 'path'

SUMMARY = "SUMMARY.md"
DIR_MD= "-/md"

summary_li = (file)->
    if await fs.pathExists(file)
        txt = await fs.readFile(file, 'utf-8')
        txt = txt.replace(/^[\r\n\s\uFEFF\xA0]+|[\r\n\s\uFEFF\xA0]+$/g, '')
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

    begin = 0
    for i, pos in index_li
        if i.startsWith("* ") and i.indexOf(suffix) > 0
            begin = pos
            index_li[pos] = dir_li.join("\n")
            ++pos
            while 1
                if pos >= index_li.length
                    break
                if index_li[pos].startsWith("* ")
                    break
                index_li.splice(pos, 1)
            break
    await fs.writeFile(index, index_li.join("\n"))
    return

_sort = (dirpath)->
    init = path.join(dirpath, "init.toml")
    sort = 1
    if await fs.pathExists(init)
        sort = (toml_config(init).read()).sort or sort
    return sort


module.exports = exports = {
    sort: (hostpath, dir)->
        await _sort(path.join(hostpath, DIR_MD, dir))

    add:(hostpath, title, file, old)->
        dirname = path.dirname(file)
        dirpath = path.join(hostpath, DIR_MD, dirname)
        summary = path.join(dirpath, SUMMARY)
        basename = path.basename(file)
        li = await summary_li(summary)
        exist = 0
        suffix = "](#{basename})"
        link = "* ["+title+suffix
        console.log file,"!!!"
        if not file.startsWith("!/")
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

        if old and not old.startsWith("!/")
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


    li : (root)->
        dir_li = []
        for dir in (await fs.readdir(root))
            if dir == "!" or dir.slice(-3) == ".md"
                continue
            summary = path.join(root, dir, SUMMARY)
            li = await summary_li(summary)
            title = undefined
            for i in li
                if i.startsWith("# ")
                    title = i.slice(1).trim()
                    break
            if not title
                title = dir

            dir_li.push([dir, title])
        return dir_li
# 1. 读取 根目录 SUMMARY.md
# 2. 根据 根目录 SUMMARY.md 查找目录
# 3. 录入 SUMMARY.md 中不存在的目录
# 4. 读取每个目录下的 SUMMARY.md 的名称（没有就用根目录的）
        # get: (hostpath)->
        #     prefix = path.join(hostpath,"-/md/")
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
