

class Cron
    constructor: ->
        @step = 10
        @_li = []
        @timer = setInterval(
            =>
                step = @step
                for i in @_li
                    i[0] -= step
                    if i[0] <= 0
                        i[0] = i[1]
                        await i[2]()
            # @step*1000
            @step*1000*60
        )

    push:(minute, func)->
        await func()
        @_li.push [
            minute
            minute
            func
        ]


CRON = new Cron()

module.exports = ->
    CRON.push.apply CRON, arguments

