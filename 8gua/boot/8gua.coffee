#!/usr/bin/env coffee

CWD = process.cwd()

require './init_path.coffee'
path = require 'path'
{uniq} = require "lodash"

yargs = require('yargs')

toml_config = require("8gua/lib/toml_config_8gua")

version = require("../../package.json").version
GIT_TEMPLATE = 'https://gitee.com/blog-8gua/blog-8gua.git'
#GIT_TEMPLATE = 'https://github.com/8gua-site/8gua-site.github.io.git'
module.exports = ->

    argv = yargs\
    .command(
        'run'
        "手动运行服务器"
        =>
        =>
            require("./8gua.srv.js")()
    ).command(
        'map [host] [path]'
        '关联 域名 和 本地目录（会自动读取CNAME、自动关联Github Page、Bitbucket Page、Gitee Page）'
        (yargs) =>
          yargs.positional('host', {
            type: 'string',
            default: '',
            describe: '想绑定的域名'
          })
        (argv) ->
            await require('./host-path')(argv.path or CWD, argv.host)
    ).command(
        'get [git]'
        '用模板仓库初始化网站'
        (yargs) =>
          yargs.positional('git', {
            type: 'string',
            # default: 'https://gitee.com/blog-8gua/blog-8gua.git',
            default: GIT_TEMPLATE,
            describe: '八卦博客默认模板'
          })
        (argv) ->
            await require('./get.coffee')(argv.git, CWD, argv.yes)
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
        await require("./cli-default")(CWD, GIT_TEMPLATE, argv)

    toml_config.write CONFIG

# now = (new Date() - 0)/1000
# if CONFIG.AUTO_UPDATE and (now-CONFIG.AUTO_UPDATE_LAST_CHECK) > 86400
#     PACKAGE = require(path.join(ROOT, 'package.json'))
#     console.log PACKAGE.version


if require.main == module
    module.exports()
