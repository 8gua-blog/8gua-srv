fs = require 'fs-extra'
path = require 'path'
{cdata} = require("./xml")
{compile} = require 'art-template'

RSS = compile """<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<title>{{title}}</title>
<subtitle>{{slogan}}</subtitle>
<id>{{@url}}</id>
<link rel="alternate" type="text/html" href="{{@url}}"/>
<link rel="self" type="application/atom+xml" href="{{@url}}/{{rss}}"/>
<updated></updated>
</feed>
"""

ENTRY = compile """<entry><id>{{@id}}</id>
<link rel="alternate" type="text/html" href="{{@link}}" />
<title>{{@h1}}</title>
<published>{{@now}}</published>
<updated>{{@now}}</updated>
<content type="html" xml:base="{{url}}">{{@html}}</content>
</entry>"""

RSS_XML = "-/rss.xml"

toml_config = require "8gua/lib/toml_config"

# 注意 h1 已经escape过了
module.exports = (hostpath, file, h1, html, url, now)->
    html = cdata(
        "<h1>#{h1}</h1>"+html
    )
    rss_xml = path.join(hostpath, RSS_XML)
    now = (now or (new Date)).toISOString().split(".")[0]+"Z"
    if await fs.pathExists(rss_xml)
        xml = await fs.readFile(rss_xml, 'utf-8')
    else
        config = toml_config(path.join(hostpath,"-/init.toml")).read()
        xml = RSS({
            url
            title:config.name
            slogan:config.slogan
            rss:RSS_XML
        })

    link = url+"/"+file
    link_id = file.slice(0,-4)
    id = "<entry><id>#{link_id}</id>"

    entry_render = ->
        ENTRY({
            h1
            html
            link
            url
            id:link_id
            now
        })

    pos = 0
    count = 1
    while 1
        pos = xml.indexOf('</entry>', pos)
        if pos < 0
            break
        else
            pos += 8
        if count >= 15
            xml = xml.slice(0,pos)+"</feed>"
            break
        count += 1

    id_pos = xml.indexOf(id)
    if id_pos > 0
        content_pos = xml.indexOf('<content ', id_pos)+1
        content_pos = xml.indexOf(">", content_pos)
        content_pos_end = xml.indexOf(']]></content>', content_pos)
        pre_html = xml.slice(
            content_pos
            content_pos_end+3
        )
        if pre_html==html
            xml = 0
        else
            xml = ([
                xml.slice(0, id_pos)
                entry_render()
                xml.slice(xml.indexOf('</entry>',content_pos_end)+8)
            ]).join('')
    else
        pos = xml.indexOf('<entry>')
        if pos < 0
            pos = xml.indexOf('</feed>')
        xml = ([
            xml.slice(0, pos)
            entry_render()
            xml.slice(pos)
        ]).join('')

    updated = "<updated>"
    updated_len = updated.length
    if xml
        pos = xml.indexOf(updated)+updated_len
        xml = ([
            xml.slice(0,pos)
            now
            xml.slice(xml.indexOf('</updated>', pos))
        ]).join('')
        await fs.writeFile(rss_xml, xml)
    return rss_xml

