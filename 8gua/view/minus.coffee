tomlify = require('tomlify-j0.4')
fs = require 'fs-extra'
path = require 'path'
save = require('8gua/util/save')
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


module.exports = {
    get:_handler ({filepath}, reply)=>
        if await fs.pathExists(filepath)
            body = await fs.readFile(filepath, "utf-8")
        else
            body = ''
        reply.send body
        return 1

    post:_handler ({body, hostpath, file}, reply)=>
        ext = path.extname(file).slice 1
        switch ext
            when 'toml'
                body = tomlify.toToml(body, {space: 0})
        save hostpath, file, body
        return
}

