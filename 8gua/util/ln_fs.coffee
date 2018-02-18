fs = require 'fs-extra'
path = require 'path'
_fs = require '8gua/util/fs'
Git = require '8gua/util/git'
sitemap = require("./sitemap")

module.exports = {
    ln: (hostpath, dirname, file, prefix="")->
        suffix = path.join("-",prefix+file)
        suffix_dir = path.dirname(suffix)
        link = path.join(hostpath, suffix)

        git = Git(hostpath)
        if not await fs.pathExists(link)
            dir = path.join(hostpath, suffix_dir)
            if not await fs.pathExists(dir)
                await fs.mkdirp(dir)
            filepath = path.join(dirname, file)
            await fs.symlink(
                path.relative(
                    suffix_dir
                    filepath
                )
                link
            )
            git.sync(suffix)
        await sitemap.new(hostpath, suffix)

    rm:(hostpath, file)->
        fpath = path.join(hostpath, "-", file)
        htm = path.join(
            "-",
            file.slice(0,-3)+".htm"
        )
        await fs.remove(
            path.join(
                hostpath,
                htm
            )
        )
        await _fs.remove(fpath)
        await sitemap.rm(
            hostpath,
            htm
        )
}
