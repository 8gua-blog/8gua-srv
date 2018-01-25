fs = require 'fs-extra'
path = require 'path'

# 发布
# 删除
# 目录改名
# 网址改名

# module.exports = {
#     write : (hostpath, file, body)->
#         filepath = path.resolve(path.join(hostpath, file))
#         await fs.mkdirp(path.dirname(filepath))
#         await fs.writeFile(
#             filepath
#             body
#         )
#     remove : (hostpath, file)->
#         filepath = path.resolve(path.join(hostpath, file))
#         await fs.remove filepath

# }
