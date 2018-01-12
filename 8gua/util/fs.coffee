path = require 'path'
fs = require 'fs-extra'

module.exports = {
    move_autoname:(root, dir, file)->
        filepath = path.join(root, file)
        ext = path.extname(file)
        basename = path.basename(file, ext)
        today = (new Date()).toISOString().slice(0,10)

        count = 0

        if file.startsWith("!/draft/") and /^\d+$/.test(basename)
            basename = today
            count = 1

        while 1
            f = path.join(dir, basename+ext)
            if await fs.pathExists(path.join(root, f))
                if count == 0
                    basename = today
                else
                    basename = today+"~"+count
                count += 1
            else
                break
        dirpath = path.join(root, dir)
        if not await fs.pathExists(dirpath)
             await fs.mkdirp(dirpath)
        if await fs.pathExists(filepath)
            await fs.move(
                filepath
                path.join(root, f)
                {overwrite: true}
            )
        return f
}
