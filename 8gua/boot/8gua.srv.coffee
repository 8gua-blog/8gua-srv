{ fork } = require('child_process')
path = require "path"



fork_run = (js)->
    forked = undefined

    run = ->
        forked =  fork(path.join(__dirname,js+'.js'))
        forked.on(
            'exit'
            (code) =>
                if 0 == code
                    run()
        )

    run()

module.exports = ->
    fork_run 'fastify'
    # fork_run 'ws'

    # setTimeout(
    #     =>
    #         forked.send 'EXIT'
    #     2000
    # )
if require.main == module
    module.exports()
