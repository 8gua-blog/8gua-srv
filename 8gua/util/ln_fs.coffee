fs = require 'fs-extra'
h1_html = require('8gua/util/marked/h1_html')
path = require 'path'
Git = require '8gua/util/git'
_fs = require '8gua/util/fs'
{escape} = require("lodash")

BODY = "</body>"

seo_html = (hostpath, dirname, file, prefix="")->
    suffix = path.join("-",prefix+file.slice(0,-3))
    [h1, html] = h1_html(await fs.readFile(path.join(hostpath, dirname, file),'utf-8'))

    h1 = escape(h1)

    template = (await fs.readFile(
        path.join(hostpath, "-S/seo.html"), 'utf-8'
    )).replace(
        "%canonical",
        "/"+suffix
    ).replace(
        BODY
        """<div class="Pbox"><div class="C macS"><div class="TXT"><h1>#{h1}</h1>#{html}</div></div></div>"""+BODY
    ).replace("<title>", "<title>#{h1}")

    await fs.writeFile(
        path.join(hostpath, suffix+'.html')
        template
    )
    return suffix

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
        git.sync(
            await seo_html.apply seo_html, arguments
        )

    rm:(hostpath, file)->
        fpath = path.join(hostpath, "-", file)
        await fs.remove(fpath.slice(0,-3)+".html")
        await _fs.remove(fpath)
}
