GIT = require('cmd-executor').git
fs = require 'fs-extra'
path = require 'path'

module.exports = {
    pull:(prefix, url)->
        if url.indexOf("://") > 0
            # https://urlhub.com/renolc/simple-url-promise.url
            dir = url.split("://").pop()
        else
            # url@urlhub.com:renolc/simple-url-promise.url
            dir = url.split("@").pop().replace(/:/g,"/")

        root = path.join(prefix, dir)
        root_git = path.join(root, ".git")

        tgit = (str)->
            console.log "#{root} >> git "+str+"\n"
            GIT("--work-tree=#{root} --git-dir=#{root_git} "+str)

        if not await fs.pathExists(root_git)
            await fs.remove(root)
            await fs.mkdirp(path.dirname(root))
            await GIT.config('--global http.postBuffer 524288000')
            await GIT.clone(url, root)
        else
            await tgit("pull")
        git_version = (await tgit "rev-parse HEAD").trim("\n\n")
        return [root, git_version]
}
