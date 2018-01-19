GIT = require('cmd-executor').git
Confirm = require('prompt-confirm')

_GIT = (str)->
    str =  str.replace(/!/g,'\\!')
    console.log "git "+str+"\n"
    GIT(str)

klaw = require('klaw')
toml_config = require("8gua/lib/toml_config_8gua")
fs = require 'fs-extra'
os = require 'os'
path = require 'path'
CONFIG = toml_config.read(
    ROOT:path.join(os.homedir(), '.8gua')
)

module.exports = (git, cwd, force)->
    if not force
        is_git = 0
        for i in ["git", "hg"]
            if await fs.pathExists(path.join(cwd,"."+i))
                is_git = 1

        if not is_git
            console.error '当前目录不是有效的GIT仓库，无法初始化'
            return

        console.log "网站模板 #{git}\n是否导入此模板到当前仓库？"
        confirm = new Confirm({
            default:false
            message:">>"
        })
        if not await confirm.run()
            return
    # git@github.com:renolc/simple-git-promise.git
    # https://github.com/renolc/simple-git-promise.git
    if git.indexOf("://") > 0
        dir = git.split("://").pop()
    else
        dir = git.split("@").pop().replace(/:/g,"/")
    console.log "更新网站模板 #{git}"
    root = path.join(CONFIG.ROOT, "git",dir)
    root_git = path.join(root, '.git')
    if not await fs.pathExists(root_git)
        await fs.remove(root)
        await fs.mkdirp(path.dirname(root))
        console.log "\ngit clone #{git} #{root}\n"
        await GIT.config('--global http.postBuffer 524288000')
        await GIT.clone(git, root)
    else
        await _GIT("--work-tree=#{root} --git-dir=#{root_git} pull")
        #await GIT("--work-tree=#{root} --git-dir=#{root_git} checkout .")

    cgit = (args)->
        _GIT "--work-tree=#{cwd} --git-dir=#{cwd}/.git "+args

    console.log "同步代码"

    root_len = root.length+1
    runing = []
    git_add = []
    on_data = (item)->
        ipath = item.path
        rpath = ipath.slice(root_len)
        if rpath.startsWith(".git") or rpath.startsWith(".hg")
            return

        is_link = item.stats.isSymbolicLink()
        if item.stats.isFile() or is_link
            cpath = path.join(cwd, rpath)
            copy = ->
                await fs.copy(ipath, cpath)
                git_add.push(rpath)

            if not is_link and await fs.pathExists(cpath)
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
            else
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
            await Promise.all(runing)
            await cgit("add -f ./"+git_add.join(" ./"))
            await cgit("""commit -m">> 8gua get #{git}\"""")
            await cgit("""push -f""")
    )

