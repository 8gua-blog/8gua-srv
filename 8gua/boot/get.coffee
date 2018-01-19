GIT = require('cmd-executor').git
toml_config = require "8gua/lib/toml_config"
Confirm = require('prompt-confirm')
git_site = require "./git_site"

_GIT = (str)->
    str =  str.replace(/!/g,'\\!')
    GIT(str)

GIT_TEMPLATE = 'https://gitee.com/blog-8gua/blog-8gua.git'

klaw = require('klaw')
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

    [root, git_version] = await git_site.pull(path.join(CONFIG.ROOT, 'git'), git)
    root_git = path.join(root, '.git')

    git_add = []
    if git_version == site_config.VERSION
        if not force
            console.log "已经是最新版了( 8gua get --force 强制刷新 )"
            return
    else
        git_add.push(SITE_CONFIG_PATH)


    cgit = (str)->
        console.log "#{cwd} >> git "+str+"\n"
        _GIT "--work-tree=#{cwd} --git-dir=#{cwd}/.git "+str

    console.log "同步代码"

    root_len = root.length+1
    runing = []
    on_data = (item)->
        ipath = item.path
        rpath = ipath.slice(root_len)
        if rpath.startsWith(".git") or rpath.startsWith(".hg")
            return
        cpath = path.join(cwd, rpath)
        copy = ->
            await fs.copy(ipath, cpath)
            git_add.push(rpath)

        if not await fs.pathExists(cpath)
            copy()
            return

        stats = item.stats

        if stats.isSymbolicLink()
            tofile = (await fs.realpath(ipath)).slice(root_len)
            cfile = (await fs.realpath(cpath)).slice(cwd.length+1)
            if tofile != cfile
                copy()
        else if stats.isFile()
            if await fs.pathExists(cpath)
                hash = await _GIT("hash-object #{ipath}")
                chash = await _GIT("hash-object #{cpath}")
                if hash == chash
                    return
                exist = 1
                try
                    await _GIT("--git-dir=#{root_git} cat-file -t #{chash}")
                catch
                    exist = 0
                if exist
                    await copy()

    klaw(
        root
    ).on(
        'data'
        (item) =>
            runing.push(on_data(item))
    ).on(
        'end'
        ->
            config.set {
                GIT:git
                VERSION : git_version
            }
            await Promise.all(runing)
            if not git_add.length
                return
            await cgit("add -f ./"+git_add.join(" ./"))
            try
                await cgit("""commit -m">> 8gua get #{git}\"""")
                await cgit("""push -f""")
            catch
                console.log ""
    )

