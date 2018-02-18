fs = require 'fs-extra'

module.exports = {
    remove: (sitemap_path, prefix, suffix)->
        sitemap = (await fs.readFile(
            sitemap_path, 'utf-8'
        ))
        pos = sitemap.indexOf(prefix)
        if pos<0
            return
        await fs.writeFile(
            sitemap_path
            sitemap.slice(0,pos) + sitemap.slice(
                sitemap.indexOf(suffix, pos+prefix.length)+suffix.length
            )
        )
}
