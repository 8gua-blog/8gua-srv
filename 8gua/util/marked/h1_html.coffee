marked = require('./init')

module.exports = (md)->
    md = (md or '').split("\n")
    title = ""
    while md.length
        i = md[0]
        if not i.trim()
            md.shift()
            continue
        if i.charAt(0) == "#"
            title = md.shift().replace(/^#/g, '').trim()
        break
    return [
        title
        marked(md.join("\n"))
    ]
