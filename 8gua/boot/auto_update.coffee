toml_config = require("8gua/lib/toml_config_8gua")
_sh = require "8gua/lib/sh.coffee"
path = require 'path'
cron = require '8gua/lib/cron'
dns = require '8gua/lib/dns.coffee'

module.exports =  (restart)->
    reinit = ->
        require("./8gua.init.coffee")(restart)

    cron 1441 , ->
        CONFIG = toml_config.read(
            {
                AUTO_UPDATE:true
                AUTO_UPDATE_TIME : 0
                ... require("8gua/lib/config_default.coffee")
            }
        )

        {HOST, ROOT, AUTO_UPDATE, AUTO_UPDATE_TIME} = CONFIG

        if not AUTO_UPDATE
            return

        now = parseInt(new Date() / 1000)
        if now - AUTO_UPDATE_TIME < 86400
            return

        path_cli = path.join(ROOT, 'cli')

        version = await dns.txt('cli-v.'+HOST)
        package_path = path.join(path_cli, "package.json")
        try
            package_json = require(package_path)
        catch
            reinit()
            return
        version_local = package_json['version']

        # console.log version, version_local, require('compare-versions')(version , version_local)

        if require('compare-versions')(version , version_local) > 0
            console.log "~~ 发现新版本 #{version} （当前版本 #{version_local}），准备升级"
            sh = (cmd)->
                _sh cmd, {cwd : path_cli}

            try
                await sh('git checkout .')
                await sh('git pull origin master')
                await sh(require("./npm.json")+" install")
                restart()
            catch
                reinit()

        CONFIG.AUTO_UPDATE_TIME = now
        toml_config.write CONFIG




