fs = require 'fs-extra'
git = require '8gua/util/git'
fontSpider = require('font-spider')
path = require 'path'
toml_config = require('8gua/lib/toml_config')
{escape} = require 'lodash'
FONT_SUFFIX = new Set("eot svg ttf woff".split(" "))

HTML = """
<style>
@font-face {
font-family: 'FONT';
src: url('FONT.eot');
src: url('FONT.eot?#font-spider') format('embedded-opentype'),
url('FONT.woff') format('woff'),
url('FONT.ttf') format('truetype'),
url('FONT.svg') format('svg');
font-weight: normal;
font-style: normal;
}
body {
font-family: 'FONT';
}
</style>
<body>BODY</body>
"""
module.exports = (req, reply)->
    {hostpath, body} = req
    {key} = req.params
     # req.hostpath
    # toml_config(
    #     path.join('.toml')
    # )
    for font, str of body

        static_prefix = '-S'

        static_dir = path.join(hostpath, static_prefix)
        prefix = path.join(static_dir, "font", font+".")

        config = toml_config(prefix+"toml")
        config.set(key, str)

        s = ''
        for _,v of config.read()
            s += v
        s = escape(s)
        html = HTML.replace(/FONT/g, font).replace('BODY', s)

        html_path = prefix+"html"
        await fs.writeFile(html_path, html)
        fontSpider.spider(
            [html_path]
            {
                slient:false
            }
        ).then(
            (webFonts)->
                await fontSpider.compressor(webFonts, {backup: true})
                await fs.remove html_path
                file_li = await fs.readdir(static_dir)
                git_li = []
                for i in file_li
                    suffix = path.extname(i).slice(1)
                    if FONT_SUFFIX.has(suffix) and i.indexOf(font+".") == 0
                        git_li.push(path.join(static_prefix, i))
                        fs.move(prefix+suffix, path.join(static_dir,i), {overwrite:true})
                git(hostpath).sync git_li
        ).catch(
            console.error
        )
    reply.send 0

# fontSpider.spider([__diranme + '/index.html'], {
#     silent: false
# }).then(function(webFonts) {
#     return fontSpider.compressor(webFonts, {backup: true});
# }).then(function(webFonts) {
#     console.log(webFonts);
# }).catch(function(errors) {
#     console.error(errors);
# });

