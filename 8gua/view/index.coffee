git = require '8gua/util/git'
tmp = require('tmp')
path = require 'path'
fs = require('fs-extra')
crypto = require('crypto')
base64url = require('base64-url')
# pump = require('./pump.js')

module.exports = {
    post:(req, reply)=>
        {hostpath} = req
        mp = req.multipart(
            (field, file, filename, encoding, mimetype) ->
                sha = crypto.createHash('SHA224')
                sha.setEncoding('base64')
                file.pipe(sha)

                tmpfile = tmp.tmpNameSync()
                stream = fs.createWriteStream(tmpfile)
                file.pipe(stream)
                file.on(
                    'end'
                    ->
                        sha.end()
                        hash = base64url.escape(sha.read())
                        if filename.indexOf(".") > 0
                            extname = path.extname(filename).slice(1)
                        else
                            extname = mimetype.split("/").pop()
                        dir_relative = path.join("-/S", extname)
                        dir = path.join(hostpath,dir_relative)
                        fs.mkdirpSync(dir)
                        filepath = path.join(dir_relative, hash+"."+extname)
                        reply.send filepath

                        stream.close(=>
                            fs.moveSync(
                                tmpfile
                                path.join(hostpath,filepath)
                                 { overwrite: true }
                            )
                            git(hostpath).sync(filepath)
                        )

                        return
                )
                return
            (err) ->
        )
        return

    get: (req, reply)=>
        reply.send 0
    options:(req, reply)=>
        reply.send ''
}
