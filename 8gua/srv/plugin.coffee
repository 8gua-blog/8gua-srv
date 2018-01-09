
content_type = 'content-type'
module.exports = (fastify)->
    fastify.addHook('onRequest', (req, res, next) =>
        if req.method == "POST"
            if req.headers[content_type] == 'text/plain'
                req.headers[content_type] = 'application/json'
        next()
    )
    register = (name)->
        fastify.register(
            require(name)
            {}
            (err) =>
                if err then throw err
        )
    register 'fastify-formbody'
    register 'fastify-multipart'

