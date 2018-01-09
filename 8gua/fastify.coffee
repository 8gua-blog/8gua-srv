
require("./boot/init_path")
path = require 'path'
global.__root =  path.resolve(__dirname, "..")
cron = require './lib/cron'

toml_config = require("8gua/lib/toml_config_8gua")
Fastify = require('fastify')

module.exports = =>
    _fastify = undefined

    CONFIG = toml_config.read(
        HOST_127_PORT: 19840
    )
    port = CONFIG.HOST_127_PORT

    host = ssl_key = ssl_cert = undefined

    reload = ->
        fastify = Fastify(
            https: {
              allowHTTP1:true
              key:ssl_key
              cert:ssl_cert
            }
        )

        require("./srv/header.coffee") fastify
        require("./srv/plugin.coffee") fastify
        require("./srv/bind.coffee") fastify

        close ->
            fastify.listen(
                port
                (err) =>
                    if (err)
                        throw err
                    console.log("fastify SERVER PORT https://#{host}:#{port}")
            )



        _fastify = fastify

    require('8gua/signal/fastify').reload.bind reload

    cron 1440, ->
        [_host, _ssl_key, _ssl_cert] = await require('./boot/ssl')()
        if _host != host or _ssl_key != ssl_key or _ssl_cert != ssl_cert
            host = _host
            ssl_cert = _ssl_cert
            ssl_key = _ssl_key
            require('8gua/signal/fastify').reload.send()
            require('8gua/ws')(host, port+1, ssl_key, ssl_cert)

    close = (callback) ->
        if _fastify
            _fastify.close callback
        else
            callback()

    require("./boot/auto_update")(
        ->
            close ->
                process.exit()
    )
    # setTimeout(
    #     ->
    #         process.on("exit", ->
    #             require("child_process").spawn(
    #                 process.argv.shift()
    #                 process.argv
    #                 {
    #                     cwd: process.cwd()
    #                     detached : true
    #                     stdio: "inherit"
    #                 }
    #             )
    #         )
    #         process.exit()

    #     3000
    # )
if require.main == module
    module.exports()

# require("./update/ssl.coffee")(module.exports)
