fs = require 'fs-extra'
path = require 'path'
Git = require '8gua/util/git'
_fs = require '8gua/util/fs'

module.exports = {
    ln: (hostpath, dirname, file, prefix="")->
        suffix = path.join("-",prefix+file)
        suffix_dir = path.dirname(suffix)
        link = path.join(hostpath, suffix)

        if not await fs.pathExists(link)
            dir = path.join(hostpath, suffix_dir)
            if not await fs.pathExists(dir)
                await fs.mkdirp(dir)
            await fs.symlink(
                path.relative(
                    suffix_dir
                    path.join(dirname, file)
                )
                link
            )
            Git(hostpath).sync(suffix)

    rm:(hostpath, file)->
        fpath = path.join(hostpath, "-", file)
        await _fs.remove(fpath)
}
