Git = require '8gua/util/git'
Str = require '8gua/util/str'
h1_htm = require('8gua/util/marked/h1_html')
fs = require 'fs-extra'
path = require 'path'
{escape, trimEnd} = require("lodash")
rss = require './rss'


BODY = "</body>"


_sitemap_htm = (hostpath, suffix_htm, h1)->
    sitemap_htm = "-/sitemap.htm"
    sitemap_htm_path = path.join(hostpath, sitemap_htm)
    if await fs.pathExists(sitemap_htm_path)
        htm = await fs.readFile(sitemap_htm_path, "utf-8")
    else
        htm = """<!DOCTYPE html><html><head><meta charset=utf-8><script>location.href="/"</script></head><body><ol></ol></body></html>"""
    link = """<a href="/#{suffix_htm}">"""
    pos = htm.indexOf(link)
    if pos > 0
        pos = pos+link.length
        htm_end = htm.slice(pos)
        htm = htm.slice(0, pos)+h1+htm_end.slice(htm_end.indexOf('</a>'))
    else
        pos = htm.indexOf('<ol>')+4
        htm = htm.slice(0, pos) + """<li>#{link}#{h1}</a></li>""" + htm.slice(pos)
    await fs.writeFile(sitemap_htm_path, htm)
    return sitemap_htm

site_host = (hostpath)->
    robots = await fs.readFile(path.join(hostpath, "robots.txt"), "utf-8")
    robots = robots.slice(robots.indexOf("Sitemap:")+8)
    return robots.slice(0, robots.indexOf("-/sitemap.xml")).trim()

module.exports = {
    rm : (hostpath, file)->
        await Str.remove(
            path.join(hostpath, "-/sitemap.htm")
            """<li><a href="/#{file}">"""
            "</li>"
        )
        await Str.remove(
            path.join(hostpath, "-/rss.xml")
            """<entry><id>#{file.slice(0,-4)}</id>"""
            "</entry>"
        )
        await Str.remove(
            path.join(hostpath, "-/sitemap.xml")
            """<url><loc>#{await site_host(hostpath)}#{file}</loc>"""
            """</lastmod></url>\n"""
        )
        return

    new : (hostpath, file)->
        suffix =  file.slice(0,-3)
        suffix_htm = suffix+".htm"
        [h1, html] = h1_htm(await fs.readFile(path.join(hostpath, file),'utf-8'))
        now = new Date
        lastmod = now.toISOString().slice(0,10)
        h1 = escape(h1) or lastmod

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
            path.join(hostpath, suffix_htm)
            template
        )

        sitemap_xml = "-/sitemap.xml"
        prefix = await site_host(hostpath)
        sitemap_xml_path = path.join(hostpath, sitemap_xml)
        if await fs.pathExists(sitemap_xml_path)
            sitemap = await fs.readFile(sitemap_xml_path, 'utf-8')
        else
            sitemap = """<?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    </urlset>"""
        loc = "<loc>#{prefix}#{suffix_htm}</loc>"
        urlset = '</urlset>'
        pos = sitemap.indexOf(loc)
        if pos > 0
            pos += loc.length
            sitemap_end = sitemap.slice(pos)
            sitemap = sitemap.slice(0, pos)+"<lastmod>#{lastmod}"+sitemap_end.slice(sitemap_end.indexOf('</lastmod>'))
        else
            sitemap = sitemap.slice(0, sitemap.indexOf(urlset)) + "<url>#{loc}<lastmod>#{lastmod}</lastmod></url>\n</urlset>"

        await fs.writeFile(sitemap_xml_path, sitemap)

        # li = sitemap.split("\n")
        # loc = "<loc>#{}"
        # for i in sitemap

        # "</urlset>"
        #"""<url><loc>http://www.example.com/foo.html</loc><lastmod>2004-12-23</lastmod></url>"""

        file_li = [
            suffix_htm
            sitemap_xml
            await _sitemap_htm(hostpath, suffix_htm, h1)
        ]
        if not file.startsWith("-/!")
            file_li.push(
                await rss(hostpath, suffix_htm, h1, html, trimEnd(prefix,"/"), now)
            )

        git = Git(hostpath).sync(file_li)

        return

}
