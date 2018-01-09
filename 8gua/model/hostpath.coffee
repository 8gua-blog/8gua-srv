toml_config = require("8gua/lib/toml_config_8gua")

HOST_PATH = undefined

module.exports = {
    set : (host, path)->
        if path
            HOST_PATH[host] = path
        else
            delete HOST_PATH[host]
        toml_config.set {
            HOST_PATH
        }

    reload:(host) ->
        {HOST_PATH} = toml_config.reload({
            HOST_PATH : {}
        })

    get : (host)->
        if not host
            return HOST_PATH
        return HOST_PATH[host]
}


module.exports.reload()
