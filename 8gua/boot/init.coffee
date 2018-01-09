path = require 'path'
fs = require 'fs-extra'

_sh = require "8gua/lib/sh.coffee"
retry = require '8gua/lib/retry.coffee'
dns = require '8gua/lib/dns.coffee'
toml_config = require("8gua/lib/toml_config_8gua")

NPM = "npm --registry=https://registry.npm.taobao.org --disturl=https://npm.taobao.org/dist"

module.exports = (callback)->
    CONFIG = toml_config.read(require("8gua/lib/config_default.coffee"))
    {ROOT , HOST} = CONFIG


    path_cli = path.join(ROOT, 'cli')
    sh = (cmd)->
        _sh cmd, {cwd : path_cli}


    retry.li(
        "更新代码"
        ->
            await dns.txt_li('cli-git.'+HOST)
        (url) ->
            await fs.remove path_cli
            await fs.mkdirs path_cli
            await sh( "git clone #{url} #{path_cli} --depth=1")
    ).then ->
        console.log "\n** 开始 安装依赖包，需要三五分钟，请稍等 …"
        sh("#{NPM} --production install").then ->
            console.log "\n** 成功 安装依赖包"
            callback()

