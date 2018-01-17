NODE_PATH = "/usr/local/lib/node_modules"
if module.paths.indexOf(NODE_PATH) < 0
    module.paths.push NODE_PATH

path = require 'path'
ROOT = path.resolve(__dirname,"../..")
require('8gua/lib/init_path')(
    ROOT
    path.join(ROOT, 'node_modules')
    NODE_PATH
)
process.chdir(ROOT)
