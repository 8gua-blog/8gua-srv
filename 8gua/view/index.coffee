git = require '8gua/util/git'
tmp = require('tmp')
path = require 'path'
fs = require('fs-extra')
pump = require('pump')
crypto = require('crypto')
base64url = require('base64-url')

module.exports = {
    post:(req, reply)=>
        {hostpath} = req
        mp = req.multipart(
            (field, file, filename, encoding, mimetype) ->


                tmpfile = tmp.tmpNameSync()

                sha = crypto.createHash('SHA224')
                sha.setEncoding('base64')
                file.pipe(sha)

                pump(
                    file
                    fs.createWriteStream(tmpfile)
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
                        file = path.join(dir_relative, hash+"."+extname)
                        fs.moveSync(
                            tmpfile
                            path.join(hostpath,file)
                             { overwrite: true }
                        )
                        git(hostpath).run 'add ./'+file
                        reply.send({
                            file
                        })
                )
            (err) ->
        )

        return


    get: (req, reply)=>
        reply.send 0
    options:(req, reply)=>
        reply.send ''
}
