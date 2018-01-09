HOST_PATH = require("8gua/model/hostpath")

module.exports = (fastify, opts, next) =>

    fastify.all(
        "reload"
        (req, reply)=>
            HOST_PATH.reload()
            reply.send HOST_PATH.get()
    )
    # fastify.all(
    #     "bind"
    #     (req, reply)=>
    #         {referer} = req.headers
    #         path = "https://#{req.headers.host}/"
    #         if referer.indexOf(path) != 0
    #             # 防止被攻击，乱绑定
    #             reply.send 1
    #             return
    #         {host} = req.params
    #         host = host.toLowerCase()
    #         {path} = req.query
    #         HOST_PATH.set(host, path)
    #         reply.send 0
    # )

    next()

