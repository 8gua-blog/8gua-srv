rp = require('request-promise-native')
toml_config = require("8gua/lib/toml_config_8gua")
fs = require 'fs-extra'
os = require 'os'
path = require 'path'
retry = require '8gua/lib/retry'
dns = require '8gua/lib/dns.coffee'


fetch = (host, path)->
    host_version = "ssl-v.#{host}"
    host_url = "ssl.#{host}"
    # version = await dns.txt(host_version)

    ssl_json = await retry.li(
        "更新 127.0.0.1 的 HTTPS 证书"
        ->
            await dns.txt_li(host_url)
        (url)->
            console.log url
            rp(url)
    )
    await fs.writeFile(
        path
        ssl_json
        'utf-8'
    )
    return JSON.parse(ssl_json)


TIME_DAY = 86400

module.exports = ->
    CONFIG = toml_config.read(
        HOST_127: "8gua.win"
        ROOT:path.join(os.homedir(), '.8gua')
    )


    HOST = CONFIG.HOST_127
    path_127_ssl = path.join(CONFIG.ROOT, "127.ssl.json")

    _fetch = ->
        ssl_json = await fetch(
            HOST
            path_127_ssl
        )
        return ssl_json


    try
        ssl_json = require('require-reload') path_127_ssl
    catch
        console.log "127.0.0.1 的 HTTPS 证书导入出错 ( #{path_127_ssl} )"
        ssl_json = await _fetch()

    version = ssl_json.shift()
    now = (new Date() - 0)/1000

    diff = (now-version)/TIME_DAY

    if diff > 88
        console.log "127.0.0.1 的 HTTPS 证书已经过期"
        ssl_json = await _fetch()
    else if diff >= 7
        _fetch()

    ssl_json.unshift HOST

    return ssl_json

if require.main == module
    console.log module.exports()


