GIT = require('cmd-executor').git
fs = require 'fs-extra'
klaw = require('klaw')
path = require 'path'

_GIT = (str)->
    str =  str.replace(/!/g,'\\!')
    GIT(str)

root_by_url = (prefix, url)->
    if url.indexOf("://") > 0
        # https://urlhub.com/renolc/simple-url-promise.url
        dir = url.split("://").pop()
    else
        # url@urlhub.com:renolc/simple-url-promise.url
        dir = url.split("@").pop().replace(/:/g,"/")

    return path.join(prefix, dir)

git = (root, str)->
    console.log "#{root} \n>> git "+str+"\n"
    GIT("--work-tree=#{root} --git-dir=#{root}/.git "+str)

module.exports = git_site = {
    pull:(root, url)->
        if not await fs.pathExists(path.join(root,".git"))
            await fs.remove(root)
            await fs.mkdirp(path.dirname(root))
            await GIT.config('--global http.postBuffer 524288000')
            await GIT.clone(url, root)
        else
            await git(root, "pull")
        git_version = (await git root, "rev-parse HEAD").trim("\n\n")
        return git_version

    upgrade:(prefix, cwd, config, force)->
        site_config = config.read()
        url = site_config.GIT
        root = root_by_url(prefix, url)
        git_version = await git_site.pull(root, url)

        git_add = []
        if git_version == site_config.VERSION
            if not force
                return 1
        else
            git_add.push("8gua.toml")

        cgit = (str)->
            console.log "#{cwd} >> git "+str+"\n"
            _GIT "--work-tree=#{cwd} --git-dir=#{cwd}/.git "+str

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

}
