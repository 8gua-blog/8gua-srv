{padStart, trimStart} = require 'lodash'
toml = require 'toml'
Git = require '8gua/util/git'
fs = require 'fs-extra'
path = require 'path'

SUMMARY = "SUMMARY.md"
DIR_MD= "-/md"

summary_li = (file)->
    if await fs.pathExists(file)
        txt = await fs.readFile(file, 'utf-8')
        if txt
            return txt.split("\n")
    return []

module.exports = {
    name : {
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
                    if i.charAt(0) == "#"
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
                for line,pos in li
                    i = trimStart(line)
                    if i.charAt(0) == '*' and i.indexOf("](#{dir})") >= 0
                        li[pos] = padStart(link, line.length-i.length, ' ')
                        count += 1
                if not count
                    li.push(link)
                txt = li.join("\n")
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
    li : (root)->
        dir_li = []
        for dir in (await fs.readdir(root))
            if dir == "!" or dir.slice(-3) == ".md"
                continue
            summary = path.join(root, dir, SUMMARY)
            li = await summary_li(summary)
            title = undefined
            for i in li
                if i.charAt(0) == "#"
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
