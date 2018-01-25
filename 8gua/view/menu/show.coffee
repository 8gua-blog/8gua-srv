DIR = "md/!"
fs = require 'fs-extra'
path = require 'path'
md_dir = require("8gua/util/md_dir")

module.exports = (req, reply)=>
    file = req.params['*']
    {hostpath} = req
    #show = await fs.pathExists(filepath)
    li = await md_dir.summary_url_li(
        path.join(
            hostpath
            DIR
        )
    )

    show = 0

    for [url] in li
        if url == file
            show = 1

    reply.send show
