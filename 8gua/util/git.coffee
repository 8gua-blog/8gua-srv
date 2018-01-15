STATUS = "conflicted created modified deleted renamed".split(" ")
Git = require('simple-git/promise')
co = require 'co'
WS_HOST = require '8gua/ws/host'
{ isArray } = require 'lodash'

# do ->
#     GIT = Git(path)
#     git = (args)->
#         GIT.raw args.split(' ')

PATH_GIT = {}

init_git = (path)->
    PATH_GIT[path] = git = Git(path)

    git.run = (args)->
        await git.raw args.split(' ')

    msg = (txt)->
        WS_HOST.msg path, txt

    _todo = []
    _ing = undefined

    sync = ->
        file_li = []
        for i in _todo
            if i.charAt(0) != '/'
                i = './'+i
            file_li.push i
        _todo = []
        try
            await git.run "add "+file_li.join(' ')
        catch err
            console.trace(err)
        await git.run 'add -u'

        status = await git.status()
        count = 0
        for i in STATUS
            count += status[i].length
        if not count
            return

        msg '正在部署更新'
        await git.commit('.')

        try
            await git.pull()
        catch err
            {conflicted} = await git.status()
            for i in conflicted
                await git.run 'checkout HEAD ./'+i
            await git.run 'add -u'
            await git.commit('.')

        repo_set = new Set()
        for i in (await git.run("config -l")).split("\n")
            if i.startsWith("remote.")
                repo = i.split(".")[1]
                if repo_set.has repo
                    continue
                repo_set.add(repo)
                await git.run 'push -f '+repo
        msg "部署成功"

        if _todo.length
            await sync()

    git.sync = co.wrap (file)->
        if isArray(file)
            _todo = _todo.concat(file)
        else
            if file
                _todo.push file

        if _ing
            return

        _ing = true
        setTimeout(
            ->
                try
                    await sync()
                catch err
                    console.log err
                    msg '更新部署失败'
                _ing = undefined
            3000
        )



module.exports = (path)->
    if not (path of PATH_GIT)
        init_git path

    return PATH_GIT[path]


