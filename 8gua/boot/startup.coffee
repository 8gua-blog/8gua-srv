#!/usr/bin/env coffee

path = require 'path'
platform = process.platform
fs = require 'fs-extra'
util = require('util')
exec = util.promisify(require('child_process').exec)

module.exports = (turn) =>
    isLinux = /linux/.test(platform)
    isMac = /darwin/.test(platform)
    isWin = /^win/.test(platform)
    if isLinux or isMac
        suffix = 'js'
    else
        suffix = 'bat'

    CMD = path.join(__dirname, "8gua.srv."+suffix)


    console.log "#{if turn then '设置' else '禁用'}开机启动"

    if isMac
        plist = "#{process.env.HOME}/Library/LaunchAgents/8gua.startup.plist"

        if turn
            data = (await fs.readFile(path.join(__dirname, '8gua.startup.plist'))).toString().replace(/#CMD/g, CMD)
            await fs.writeFile(plist, data)
            try
                {stderr} = await exec("reattach-to-user-namespace -l launchctl load -w #{plist}")
            catch
                {stderr} = await exec("launchctl load -w #{plist}")
            if stderr
                if stderr.indexOf('service already loaded') > 0
                    return
                console.log stderr
                if stderr.indexOf('Operation not permitted') > 0
                    console.log 'Mac 请不要在 tmux 中运行 ！\n（参见 reattach-to-user-namespace: The Fix For Your tmux in OS X http://t.cn/RYXnkSN ）'

        else
            {stdout,stderr} = await exec("launchctl unload #{plist}")
            if stderr
                if stderr.indexOf('Could not find specified service') > 0
                    return
                console.log stderr
    else
        cli = new AutoLaunch {
            name: '8gua'
            CMD
        }
        cli.isEnabled().then((isEnabled) ->
            if turn
                if isEnabled
                    return
                cli.enable()
            else
                if not isEnabled
                    return
                cli.disable()

        )


