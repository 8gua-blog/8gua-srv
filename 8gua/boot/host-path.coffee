{to_root} = require "8gua/util/path"
rp = require('request-promise-native')
path = require 'path'
fs = require 'fs-extra'
ini = require 'ini'
toml_config = require("8gua/lib/toml_config_8gua")
{isEmpty} = require("lodash")

PAGE_SUFFIX = [
    "github.io.git",
    "bitbucket.io.git",
]

# http://8gua.gitee.io/
# http://8gua.oschina.io/

url_page_host = (url)->
    for i in PAGE_SUFFIX
        if url.indexOf("."+i) > 0
            return [url.split("/").pop().slice(0, -4)]

    url = url.replace("https://gitee.com/", "git@gitee.com:")
    if url.indexOf("@gitee.com:") > 0
        url = url.split(":").pop().slice(0,-4)
        url = url.split("/")
        host = url[0]
        if host == url[1] and host
            return [
               "#{host}.gitee.io"
               "#{host}.oschina.io"
            ]

module.exports = (root)->
    host_path = {}


    for p in await to_root(root)
        git_path = path.join(p, '.git/config')

        if await fs.pathExists(git_path)
            config = ini.parse(await fs.readFile(git_path, "utf-8"))

            for k,v of config
                if k.slice(0, 7) == "remote "
                    try
                        host_li = url_page_host(v.url)
                    catch
                        continue
                    if host_li
                        for host in host_li
                            host_path[host] = p
            cname_path = path.join(p, 'CNAME')
            try
                cname = await fs.readFile(cname_path, 'utf-8')
            catch
                cname = 0

            if cname
                cname = cname.replace(/\r/g, "\n").split("\n")
                for i in cname
                    i = i.trim()
                    if i
                        host_path[i] = p

            break


    if isEmpty(host_path)
        console.log """未找到可以映射的页面，`8gua -h` 查看帮助"""
    else
        for k,v of host_path
            console.log "映射 #{k} -> #{v}"
        toml_config.add {HOST_PATH:host_path}
        rp(
            "https://127.0.0.1:19840/api/reload"
            {
                strictSSL:false
            }
        ).catch(
            ->
        )




