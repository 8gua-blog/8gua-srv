#!/usr/bin/env coffee

CWD = process.cwd()

require './init_path.coffee'
path = require 'path'
{uniq} = require "lodash"

yargs = require('yargs')

toml_config = require("8gua/lib/toml_config_8gua")

version = require("../../package.json").version

module.exports = ->

    argv = yargs\
    .command(
        'get [git]'
        '用模板仓库初始化网站'
        (yargs) =>
          yargs.positional('git', {
            type: 'string',
            default: 'https://gitee.com/blog-8gua/blog-8gua.git',
            describe: '八卦博客默认模板'
          })
        (argv) ->
            require('./get.coffee')(argv.git)
    ).option('help', {
        alias:'h'
        describe: '显示帮助文档'
    }).option('startup',{
        alias : 's'
        describe: '启用开机启动'
        type: 'boolean'
    }).option('startup_off', {
        describe: '禁用开机启动'
        type: 'boolean'
    }).usage("""8gua #{version} - 下一代分布式互联网\n官方主页 https://8gua.github.io 。""").version(
        version
    ).argv

    CONFIG = toml_config.read()

    if not argv.startup_off and CONFIG.STARTUP == undefined
        argv.startup = true

    if argv.startup
        CONFIG.STARTUP = true
    else if argv.startup_off
        CONFIG.STARTUP = false

    if argv.startup or argv.startup_off
        require("./startup.coffee") CONFIG.STARTUP

    if process.argv.length == 2
        await require("./host-path")(CWD)

    toml_config.write CONFIG

# now = (new Date() - 0)/1000
# if CONFIG.AUTO_UPDATE and (now-CONFIG.AUTO_UPDATE_LAST_CHECK) > 86400
#     PACKAGE = require(path.join(ROOT, 'package.json'))
#     console.log PACKAGE.version


if require.main == module
    module.exports()
