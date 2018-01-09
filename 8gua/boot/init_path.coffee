path = require 'path'
ROOT = path.resolve(__dirname,"../..")
require('8gua/lib/init_path')(
    ROOT
    path.join(ROOT, 'node_modules')
)
process.chdir(ROOT)
