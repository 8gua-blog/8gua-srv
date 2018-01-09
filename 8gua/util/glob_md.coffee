path = require 'path'
glob_mtime_size = require('8gua/util/glob_mtime_size')

module.exports = (root, ignore=["SUMMARY.md"])=>
    glob_mtime_size(
        path.join(root, "*.md")
        ignore
    )

