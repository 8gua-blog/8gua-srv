
module.exports = (fastify)->

    fastify.register(
        require('8gua/route/api.coffee'), { prefix: '/api/' }
        #require('8gua/route/api.coffee'), { prefix: '/~:host/' }
    )
    fastify.register(
        require('8gua/route/_site.coffee'), { prefix: '/' }
    )
