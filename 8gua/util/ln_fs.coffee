fs = require 'fs-extra'
path = require 'path'
Git = require '8gua/util/git'

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
        await fs.remove fpath
        dir = path.dirname(fpath)
        while 1
            if await fs.pathExists(dir)
                files = await fs.readdir(dir)
                if not files.length
                    await fs.remove dir
                    dir = path.basename(dir)
                    continue
            break
}
