fs = require 'fs-extra'
h1_html = require('8gua/util/marked/h1_html')
path = require 'path'
Git = require '8gua/util/git'
_fs = require '8gua/util/fs'
{escape} = require("lodash")

BODY = "</body>"

seo_html = (hostpath, dirname, file)->
    suffix = path.join("-", file.slice(0,-3))
    suffix_html = suffix+".htm"
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
        path.join(hostpath, suffix_html)
        template
    )

    sitemap_xml = "-/sitemap.xml"
    robots = await fs.readFile(path.join(hostpath, "robots.txt"), "utf-8")
    robots = robots.slice(robots.indexOf("Sitemap:")+8)
    prefix = robots.slice(0, robots.indexOf(sitemap_xml)).trim()
    sitemap_xml_path = path.join(hostpath, sitemap_xml)
    if await fs.pathExists(sitemap_xml_path)
        sitemap = await fs.readFile(sitemap_xml_path, 'utf-8')
    else
        sitemap = """<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
</urlset>"""
    loc = "<loc>#{prefix}#{suffix_html}</loc>"
    lastmod = (new Date).toISOString().slice(0,10)
    urlset = '</urlset>'
    pos = sitemap.indexOf(loc)
    if pos > 0
        pos += loc.length
        sitemap_end = sitemap.slice(pos)
        sitemap = sitemap.slice(0, pos)+"<lastmod>#{lastmod}"+sitemap_end.slice(sitemap_end.indexOf('</lastmod>'))
    else
        sitemap = sitemap.slice(0, sitemap.indexOf(urlset)) + "<url>#{loc}<lastmod>#{lastmod}</lastmod></url>\n</urlset>"
    await fs.writeFile(sitemap_xml_path, sitemap)


    sitemap_html_path = path.join(hostpath, "-/sitemap.htm")
    if await fs.pathExists(sitemap_html_path)
        sitemap_html = await fs.readFile(sitemap_html_path, "utf-8")
    else
        sitemap_html = """<!DOCTYPE html><html><head><meta charset=utf-8><script>location.href="/"</script></head><body><ol></ol></body></html>"""
    link = """<a href="/#{suffix_html}">"""
    title = h1 or lastmod
    pos = sitemap_html.indexOf(link)
    if pos > 0
        pos = pos+link.length
        sitemap_html_end = sitemap_html.slice(pos)
        sitemap_html = sitemap_html.slice(0, pos)+title+sitemap_html_end.slice(sitemap_html_end.indexOf('</a>'))
    else
        pos = sitemap_html.indexOf('<ol>')+4
        sitemap_html = sitemap_html.slice(0, pos) + """<li>#{link}#{title}</a></li>""" + sitemap_html.slice(pos)
    await fs.writeFile(sitemap_html_path, sitemap_html)
    # li = sitemap.split("\n")
    # loc = "<loc>#{}"
    # for i in sitemap

    # "</urlset>"
    #"""<url><loc>http://www.example.com/foo.html</loc><lastmod>2004-12-23</lastmod></url>"""

    git = Git(hostpath).sync([
        sitemap_html_path
        sitemap_xml_path
    ])
    return suffix_html

module.exports = {
    ln: (hostpath, dirname, file, prefix="")->
        prefix_file=  prefix+file
        suffix = path.join("-",prefix_file)
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
            await seo_html(hostpath, dirname, prefix_file)
        )

    rm:(hostpath, file)->
        fpath = path.join(hostpath, "-", file)
        await fs.remove(fpath.slice(0,-3)+".html")
        await _fs.remove(fpath)
}
