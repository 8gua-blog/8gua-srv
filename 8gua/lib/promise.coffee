
class _Promise extends Promise
    fail : ->
        Promise.prototype.catch.apply @, arguments
        return @

module.exports = (func)->
    new _Promise(func)

