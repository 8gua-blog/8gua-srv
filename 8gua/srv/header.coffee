HOST_PATH = require("8gua/model/hostpath")
url = require('url')


module.exports = (fastify) ->
    fastify.addHook(
        'preHandler'
        (req, reply, next) =>
            {referer, origin} = req.headers
            if not referer and origin
                referer = origin
                req.headers.referer = origin
            if referer
                p = url.parse(referer)
                req.headers.refer = p
                {host} = p
                reply.header('Access-Control-Allow-Origin' , p.protocol+"//"+host)
                hostpath = HOST_PATH.get(host)
                if hostpath
                    req.hostpath = hostpath
            reply.header('Access-Control-Allow-Credentials', "true")
            next()
            # reply.send(0)
    )
