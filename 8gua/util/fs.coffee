path = require 'path'
fs = require 'fs-extra'
ln_fs = require '8gua/util/ln_fs'

module.exports = {
    move_autoname:(hostpath, dir, file)->
        if file.startsWith("$/")
            base = "-"
        else
            base = "md"
        root = path.join(hostpath, base)
        filepath = path.join(root, file)


        ext = path.extname(file)
        basename = path.basename(file, ext)
        today = (new Date()).toISOString().slice(0,10)

        count = 0

        if file.startsWith("$/")
            if /^\d+$/.test(basename)
                basename = today
                count = 1
        else
            if file.startsWith("!/")
                link_path = "!"+file.slice(2)
            else
                link_path = file
            await ln_fs.rm(hostpath, link_path)

        while 1
            f = path.join(dir, basename+ext)
            if await fs.pathExists(path.join(hostpath, f))
                if count == 0
                    basename = today
                else
                    basename = today+"."+count
                count += 1
            else
                break
        dirpath = path.join(hostpath, dir)
        if not await fs.pathExists(dirpath)
             await fs.mkdirp(dirpath)

        if await fs.pathExists(filepath)
            await fs.move(
                filepath
                path.join(hostpath, f)
                {overwrite: true}
            )
        return f.slice(f.indexOf("/")+1)
}
