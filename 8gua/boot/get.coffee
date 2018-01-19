GIT = require('cmd-executor').git
toml_config = require "8gua/lib/toml_config"
Confirm = require('prompt-confirm')
git_site = require "./git_site"

GIT_TEMPLATE = 'https://gitee.com/blog-8gua/blog-8gua.git'

fs = require 'fs-extra'
os = require 'os'
path = require 'path'

CONFIG = require("8gua/lib/toml_config_8gua").read(
    ROOT:path.join(os.homedir(), '.8gua')
)

SITE_CONFIG_PATH = "8gua.toml"

module.exports = (git, cwd, force)->
    config_path = path.join(cwd, SITE_CONFIG_PATH)
    config = toml_config(config_path)

    site_config = {}

    if await fs.pathExists(config_path)
        site_config = config.read()

    if not git
        git = site_config.GIT or GIT_TEMPLATE

    if not force and not site_config.GIT
        is_git = 0
        for i in ["git", "hg"]
            if await fs.pathExists(path.join(cwd,"."+i))
                is_git = 1

        if not is_git
            console.error '当前目录不是有效的GIT仓库，无法初始化'
            return

        console.log "\n\n\n网站模板 #{git}\n是否应用此模板到当前仓库？"
        confirm = new Confirm({
            default:false
            message:">>"
        })
        if not await confirm.run()
            return

    console.log "更新网站模板 #{git}"

    prefix = path.join(CONFIG.ROOT, 'git')

    console.log "同步代码"

    if site_config.GIT != git
        config.set('GIT', git)

    r = await git_site.upgrade(prefix, cwd, config, force)
    if r == 1
        console.log "已经是最新版了( 8gua get --force 强制刷新 )"

