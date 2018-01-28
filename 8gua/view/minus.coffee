send = require('send')
tomlify = require('tomlify-j0.4')
fs = require 'fs-extra'
path = require 'path'
save = require('8gua/util/save')
Git = require '8gua/util/git'
_filepath = (req)->
    {hostpath} = req

    file = req.params['*']
    if not file
        return 3

    file = path.join('-', file)
    filepath = path.resolve(path.join(hostpath, file))

    # 防止被黑客攻击
    if filepath.indexOf(hostpath) != 0
        return 4

    req.filepath = filepath
    req.file = file

    return 0

_handler = (callback)=>
    (req, reply)=>
        err = _filepath(req)
        if err
            reply.send err
            return


        if not (await callback(req, reply))
            reply.send err
        return

HOOK = {
    "-/init.toml" : (req)->
        origin = req.headers.origin
        {hostpath, body} = req
        url = (
            origin.slice(0, origin.indexOf("://")+3) + body.host+"/-/sitemap.xml"
        ).toLowerCase()

        robots_txt= "robots.txt"
        robots_path = path.join(hostpath, robots_txt)
        if await fs.pathExists(robots_path)
            robots = await fs.readFile(robots_path, "utf-8")
        else
            robots = """User-agent: *"""

        li = robots.split("\n")
        sitemap_line = "Sitemap: "+url
        has = 0
        for i, pos in li
            if i.trim().startsWith("Sitemap:")
                li[pos] = sitemap_line
                has = 1
                break
        if not has
            li.push(sitemap_line)
        await fs.writeFile(robots_path, li.join("\n"))
        Git(hostpath).sync(robots_txt)
        return
}

TEXT = new Set("md toml".split(" "))

module.exports = {
    get:_handler (req, reply)=>
        {filepath} = req
        if await fs.pathExists(filepath)
            send(req, filepath).pipe(reply.res)
        else
            reply.send ''
        return 1

    post:_handler (req, reply)=>
        {body, hostpath, file} = req
        ext = path.extname(file).slice 1
        switch ext
            when 'toml'
                if file of HOOK
                    body = (await HOOK[file](req)) or body
                body = tomlify.toToml(body, {space: 0})
        save hostpath, file, body
        return
}

