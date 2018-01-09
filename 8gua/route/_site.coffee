global.raise = (err)->
    if typeof(err) == 'string'
        throw err

    for k of err
        if err[k] != undefined
            throw err

beforeHandler = (req, reply, next)->

    if not req.headers.referer
        reply.send 1
        return

    {hostpath} = req

    if not req.hostpath
        reply.send 2
        return
    next()

co = require('co')

module.exports = (fastify, opts, next) =>

    bind = (action, url, mod)=>
        _mod = (req,reply)->
            try
                co(mod.apply(@,arguments)).catch(
                    (err) =>
                        reply.code(412).send err
                )
            catch err
                reply.code(412).send err

        fastify[action](
            url
            {
                beforeHandler
            }
            _mod
        )

    srv = {
        post : (url, mod)=>
            bind('post', url, mod)

        get : (url, mod)=>
            bind('get', url, mod)

        map : (url, mod)=>
            for method, func of mod
                bind(method, url, func)
    }
    for method, li of require("./site")
        for url_mod in li
            [url,mod] = url_mod.split(" ")
            mod = mod or url
            srv[method](url, require("8gua/view/"+mod))


    next()

