path = require 'path'
module.exports = {
    to_root : (dir)->
        r = []
        while 1
            r.push dir
            p = path.dirname(dir)
            if dir == p
                break
            dir = p
        return r
}
