###*
# marked - a markdown parser
# Copyright (c) 2011-2014, Christopher Jeffrey. (MIT Licensed)
# https://github.com/chjj/marked
###

noop = ->
replace = (regex, opt) ->
    regex = regex.source
    opt = opt or ''
    self = (name, val) ->
        if !name
            return new RegExp(regex, opt)
        val = val.source or val
        val = val.replace(/(^|[^\[])\^/g, '$1')
        regex = regex.replace(name, val)
        self


###*
# Block-Level Grammar
###

block = {
    newline: /^\n+/
    code: /^( {4}[^\n]+\n*)+/
    fences: noop
    hr: /^( *[-*_]){3,} *(?:\n+|$)/
    heading: /^ *(#{1,6}) *([^\n]+?) *#* *(?:\n+|$)/
    nptable: noop
    lheading: /^([^\n]+)\n *(=|-){2,} *(?:\n+|$)/
    blockquote: /^( *>[^\n]+(\n(?!def)[^\n]+)*\n*)+/
    list: /^( *)(bull) [\s\S]+?(?:hr|def|\n{2,}(?! )(?!\1bull )\n*|\s*$)/
    html: /^ *(?:comment *(?:\n|\s*$)|closed *(?:\n{2,}|\s*$)|closing *(?:\n{2,}|\s*$))/
    def: /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +["(]([^\n]+)[")])? *(?:\n+|$)/
    table: noop
    paragraph: /^((?:[^\n]+\n?(?!hr|heading|lheading|blockquote|tag|def))+)\n*/
    text: /^[^\n]+/
}
###*
# Block Lexer
###

Lexer = (options) ->
    @tokens = []
    @tokens.links = {}
    @options = options or marked.defaults
    @rules = block.normal
    if @options.gfm
        if @options.tables
            @rules = block.tables
        else
            @rules = block.gfm
    return

###*
# Inline Lexer & Compiler
###

InlineLexer = (links, options) ->
    @options = options or marked.defaults
    @links = links
    @rules = inline.normal
    @renderer = @options.renderer or new Renderer
    @renderer.options = @options
    if !@links
        throw new Error('Tokens array requires a `links` property.')
    if @options.gfm
        if @options.breaks
            @rules = inline.breaks
        else
            @rules = inline.gfm
    else if @options.pedantic
        @rules = inline.pedantic
    return

###*
# Renderer
###

Renderer = (options) ->
    @options = options or {}
    return

###*
# Parsing & Compiling
###

Parser = (options) ->
    @tokens = []
    @token = null
    @options = options or marked.defaults
    @options.renderer = @options.renderer or new Renderer
    @renderer = @options.renderer
    @renderer.options = @options
    return

###*
# Helpers
###

escape = (html, encode) ->
    html.\
    replace((if not encode then /&(?!#?\w+;)/g else /&/g), '&amp;').\
    replace(/</g, '&lt;').\
    replace(/>/g, '&gt;').\
    replace(/"/g, '&quot;').\
    replace /'/g, '&#39;'


unescape = (html) ->
    # explicitly match decimal, hex, and named HTML entities
    html.replace /&(#(?:\d+)|(?:#x[0-9A-Fa-f]+)|(?:\w+));?/ig, (_, n) ->
        n = n.toLowerCase()
        if n == 'colon'
            return ':'
        if n.charAt(0) == '#'
            return if n.charAt(1) == 'x' then String.fromCharCode(parseInt(n.substring(2), 16)) else String.fromCharCode(+n.substring(1))
        ''


resolveUrl = (base, href) ->
    if !baseUrls[' ' + base]
        # we can ignore everything in base after the last slash of its path component,
        # but we might need to add _that_
        # https://tools.ietf.org/html/rfc3986#section-3
        if /^[^:]+:\/*[^/]*$/.test(base)
            baseUrls[' ' + base] = base + '/'
        else
            baseUrls[' ' + base] = base.replace(/[^/]*$/, '')
    base = baseUrls[' ' + base]
    if href.slice(0, 2) == '//'
        base.replace(/:[^]*/, ':') + href
    else if href.charAt(0) == '/'
        base.replace(/(:\/*[^/]*)[^]*/, '$1') + href
    else
        base + href


merge = (obj) ->
    i = 1
    target = undefined
    key = undefined
    while i < arguments.length
        target = arguments[i]
        for key of target
            `key = key`
            if Object::hasOwnProperty.call(target, key)
                obj[key] = target[key]
        i++
    obj

###*
# Marked
###

marked = (src, opt, callback) ->
    if callback or typeof opt == 'function'
        if !callback
            callback = opt
            opt = null
        opt = merge({}, marked.defaults, opt or {})
        highlight = opt.highlight
        tokens = undefined
        pending = undefined
        i = 0
        try
            tokens = Lexer.lex(src, opt)
        catch e
            return callback(e)
        pending = tokens.length

        done = (err) ->
            if err
                opt.highlight = highlight
                return callback(err)
            out = undefined
            try
                out = Parser.parse(tokens, opt)
            catch e
                err = e
            opt.highlight = highlight
            if err then callback(err) else callback(null, out)

        if !highlight or highlight.length < 3
            return done()
        delete opt.highlight
        if !pending
            return done()
        while i < tokens.length
            ((token) ->
                if token.type != 'code'
                    return --pending or done()
                highlight token.text, token.lang, (err, code) ->
                    if err
                        return done(err)
                    if code == null or code == token.text
                        return --pending or done()
                    token.text = code
                    token.escaped = true
                    --pending or done()
                    return
            ) tokens[i]
            i++
        return
    if opt
        opt = merge({}, marked.defaults, opt)
    try
        return Parser.parse(Lexer.lex(src, opt), opt)
    catch e
        e.message += '\nPlease report this to https://github.com/chjj/marked.'
        if (opt or marked.defaults).silent
            return '<p>An error occured:</p><pre>' + escape(e.message + '', true) + '</pre>'
        throw e
    return

block.bullet = /(?:[*+-]|\d+\.)/
block.item = /^( *)(bull) [^\n]*(?:\n(?!\1bull )[^\n]*)*/
block.item = replace(block.item, 'gm')(/bull/g, block.bullet)()
block.list = replace(block.list)(/bull/g, block.bullet)('hr', '\\n+(?=\\1?(?:[-*_] *){3,}(?:\\n+|$))')('def', '\\n+(?=' + block.def.source + ')')()
block._tag = '(?!(?:' + 'a|em|strong|small|s|cite|q|dfn|abbr|data|time|code' + '|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo' + '|span|br|wbr|ins|del|img)\\b)\\w+(?!:/|[^\\w\\s@]*@)\\b'
block.html = replace(block.html)('comment', /<!--[\s\S]*?-->/)('closed', /<(tag)[\s\S]+?<\/\1>/)('closing', /<tag(?:"[^"]*"|'[^']*'|[^'">])*?>/)(/tag/g, block._tag)()
block.paragraph = replace(block.paragraph)('hr', block.hr)('heading', block.heading)('lheading', block.lheading)('blockquote', block.blockquote)('tag', '<' + block._tag)('def', block.def)()

###*
# Normal Block Grammar
###

block.normal = merge({}, block)

###*
# GFM Block Grammar
###

block.gfm = merge({}, block.normal,
    fences: /^ *(`{3,}|~{3,})[ \.]*(\S+)? *\n([\s\S]*?)\s*\1 *(?:\n+|$)/
    paragraph: /^/
    heading: /^ *(#{1,6}) +([^\n]+?) *#* *(?:\n+|$)/)
block.gfm.paragraph = replace(block.paragraph)('(?!', '(?!' + block.gfm.fences.source.replace('\\1', '\\2') + '|' + block.list.source.replace('\\1', '\\3') + '|')()

###*
# GFM + Tables Block Grammar
###

block.tables = merge({}, block.gfm,
    nptable: /^ *(\S.*\|.*)\n *([-:]+ *\|[-| :]*)\n((?:.*\|.*(?:\n|$))*)\n*/
    table: /^ *\|(.+)\n *\|( *[-:]+[-| :]*)\n((?: *\|.*(?:\n|$))*)\n*/)

###*
# Expose Block Rules
###

Lexer.rules = block

###*
# Static Lex Method
###

Lexer.lex = (src, options) ->
    lexer = new Lexer(options)
    lexer.lex src

###*
# Preprocessing
###

Lexer::lex = (src) ->
    src = src.replace(/\r\n|\r/g, '\n').replace(/\t/g, '    ').replace(/\u00a0/g, ' ').replace(/\u2424/g, '\n')
    @token src, true

###*
# Lexing
###

Lexer::token = (src, top, bq) ->
    `var src`
    src = src.replace(/^ +$/gm, '')
    next = undefined
    loose = undefined
    cap = undefined
    bull = undefined
    b = undefined
    item = undefined
    space = undefined
    i = undefined
    l = undefined
    while src
        # newline
        if cap = @rules.newline.exec(src)
            src = src.substring(cap[0].length)
            if cap[0].length > 1
                @tokens.push type: 'space'
        # code
        if cap = @rules.code.exec(src)
            src = src.substring(cap[0].length)
            cap = cap[0].replace(/^ {4}/gm, '')
            @tokens.push
                type: 'code'
                text: if !@options.pedantic then cap.replace(/\n+$/, '') else cap

            continue
        # fences (gfm)
        if cap = @rules.fences.exec(src)
            src = src.substring(cap[0].length)
            @tokens.push
                type: 'code'
                lang: cap[2]
                text: cap[3] or ''

            continue
        # heading
        if cap = @rules.heading.exec(src)
            src = src.substring(cap[0].length)
            @tokens.push
                type: 'heading'
                depth: cap[1].length
                text: cap[2]

            continue
        # table no leading pipe (gfm)
        if top and (cap = @rules.nptable.exec(src))
            src = src.substring(cap[0].length)
            item =
                type: 'table'
                header: cap[1].replace(/^ *| *\| *$/g, '').split(RegExp(' *\\| *'))
                align: cap[2].replace(/^ *|\| *$/g, '').split(RegExp(' *\\| *'))
                cells: cap[3].replace(/\n$/, '').split('\n')
            i = 0
            while i < item.align.length
                if /^ *-+: *$/.test(item.align[i])
                    item.align[i] = 'right'
                else if /^ *:-+: *$/.test(item.align[i])
                    item.align[i] = 'center'
                else if /^ *:-+ *$/.test(item.align[i])
                    item.align[i] = 'left'
                else
                    item.align[i] = null
                ++i
            i = 0
            while i < item.cells.length
                item.cells[i] = item.cells[i].split(RegExp(' *\\| *'))
                ++i

            @tokens.push item

            continue
        # lheading
        if cap = @rules.lheading.exec(src)
            src = src.substring(cap[0].length)
            @tokens.push
                type: 'heading'
                depth: if cap[2] == '=' then 1 else 2
                text: cap[1]

            continue
        # hr
        if cap = @rules.hr.exec(src)
            src = src.substring(cap[0].length)
            @tokens.push type: 'hr'

            continue
        # blockquote
        if cap = @rules.blockquote.exec(src)
            src = src.substring(cap[0].length)
            @tokens.push type: 'blockquote_start'
            cap = cap[0].replace(/^ *> ?/gm, '')
            # Pass `top` to keep the current
            # "toplevel" state. This is exactly
            # how markdown.pl works.
            @token cap, top, true
            @tokens.push type: 'blockquote_end'

            continue
        # list
        if cap = @rules.list.exec(src)
            src = src.substring(cap[0].length)
            bull = cap[2]
            @tokens.push
                type: 'list_start'
                ordered: bull.length > 1
            # Get each top-level item.
            cap = cap[0].match(@rules.item)
            next = false
            l = cap.length
            i = 0
            while i < l
                item = cap[i]
                # Remove the list item's bullet
                # so it is seen as the next token.
                space = item.length
                item = item.replace(/^ *([*+-]|\d+\.) +/, '')
                # Outdent whatever the
                # list item contains. Hacky.
                if ~item.indexOf('\n ')
                    space -= item.length
                    item = if !@options.pedantic then item.replace(new RegExp('^ {1,' + space + '}', 'gm'), '') else item.replace(/^ {1,4}/gm, '')
                # Determine whether the next list item belongs here.
                # Backpedal if it does not belong in this list.
                if @options.smartLists and i != l - 1
                    b = block.bullet.exec(cap[i + 1])[0]
                    if bull != b and !(bull.length > 1 and b.length > 1)
                        src = cap.slice(i + 1).join('\n') + src
                        i = l - 1
                # Determine whether item is loose or not.
                # Use: /(^|\n)(?! )[^\n]+\n\n(?!\s*$)/
                # for discount behavior.
                loose = next or /\n\n(?!\s*$)/.test(item)
                if i != l - 1
                    next = item.charAt(item.length - 1) == '\n'
                    if !loose
                        loose = next
                @tokens.push type: if loose then 'loose_item_start' else 'list_item_start'
                # Recurse.
                @token item, false, bq
                @tokens.push type: 'list_item_end'
                ++i

            @tokens.push type: 'list_end'

            continue
        # html
        if cap = @rules.html.exec(src)
            src = src.substring(cap[0].length)
            @tokens.push
                type: if @options.sanitize then 'paragraph' else 'html'
                pre: !@options.sanitizer and (cap[1] == 'pre' or cap[1] == 'script' or cap[1] == 'style')
                text: cap[0]

            continue
        # def
        if !bq and top and (cap = @rules.def.exec(src))
            src = src.substring(cap[0].length)
            @tokens.links[cap[1].toLowerCase()] =
                href: cap[2]
                title: cap[3]

            continue
        # table (gfm)
        if top and (cap = @rules.table.exec(src))
            src = src.substring(cap[0].length)
            item =
                type: 'table'
                header: cap[1].replace(/^ *| *\| *$/g, '').split(RegExp(' *\\| *'))
                align: cap[2].replace(/^ *|\| *$/g, '').split(RegExp(' *\\| *'))
                cells: cap[3].replace(/(?: *\| *)?\n$/, '').split('\n')
            i = 0
            while i < item.align.length
                if /^ *-+: *$/.test(item.align[i])
                    item.align[i] = 'right'
                else if /^ *:-+: *$/.test(item.align[i])
                    item.align[i] = 'center'
                else if /^ *:-+ *$/.test(item.align[i])
                    item.align[i] = 'left'
                else
                    item.align[i] = null
                ++i

            i = 0
            while i < item.cells.length
                item.cells[i] = item.cells[i].replace(/^ *\| *| *\| *$/g, '').split(RegExp(' *\\| *'))
                ++i

            @tokens.push item

            continue
        # top-level paragraph
        if top and (cap = @rules.paragraph.exec(src))
            src = src.substring(cap[0].length)
            @tokens.push
                type: 'paragraph'
                text: if cap[1].charAt(cap[1].length - 1) == '\n' then cap[1].slice(0, -1) else cap[1]

            continue
        # text
        if cap = @rules.text.exec(src)
            # Top-level should never reach here.
            src = src.substring(cap[0].length)
            @tokens.push
                type: 'text'
                text: cap[0]

            continue
        if src
            throw new Error('Infinite loop on byte: ' + src.charCodeAt(0))
    @tokens

###*
# Inline-Level Grammar
###

inline =
    escape: /^\\([\\`*{}\[\]()#+\-.!_>])/
    autolink: /^<([^ >]+(@|:\/)[^ >]+)>/
    url: noop
    tag: /^<!--[\s\S]*?-->|^<\/?\w+(?:"[^"]*"|'[^']*'|[^'">])*?>/
    link: /^!?\[(inside)\]\(href\)/
    reflink: /^!?\[(inside)\]\s*\[([^\]]*)\]/
    nolink: /^!?\[((?:\[[^\]]*\]|[^\[\]])*)\]/
    strong: /^\*\*([\s\S]+?)\*\*(?!\*)/
    u: /^__([\s\S]+?)__(?!_)/
    em: /^\b_((?:[^_]|__)+?)_\b|^\*((?:\*\*|[\s\S])+?)\*(?!\*)/
    code: /^(`+)([\s\S]*?[^`])\1(?!`)/
    br: /^ {2,}\n(?!\s*$)/
    del: noop
    text: /^[\s\S]+?(?=[\\<!\[_*`]| {2,}\n|$)/
inline._inside = /(?:\[[^\]]*\]|[^\[\]]|\](?=[^\[]*\]))*/
inline._href = /\s*<?([\s\S]*?)>?(?:\s+['"]([\s\S]*?)['"])?\s*/
inline.link = replace(inline.link)('inside', inline._inside)('href', inline._href)()
inline.reflink = replace(inline.reflink)('inside', inline._inside)()

###*
# Normal Inline Grammar
###

inline.normal = merge({}, inline)

###*
# Pedantic Inline Grammar
###

inline.pedantic = merge({}, inline.normal
    {
        u:/^__(?=\S)([\s\S]*?\S)__(?!_)/
        strong: /^\*\*(?=\S)([\s\S]*?\S)\*\*(?!\*)/
        em: /^_(?=\S)([\s\S]*?\S)_(?!_)|^\*(?=\S)([\s\S]*?\S)\*(?!\*)/
    }
)

###*
# GFM Inline Grammar
###

inline.gfm = merge({}, inline.normal,
    escape: replace(inline.escape)('])', '~|])')()
    url: /^(https?:\/\/[^\s<]+[^<.,:;"')\]\s])/
    del: /^~~(?=\S)([\s\S]*?\S)~~/
    text: replace(inline.text)(']|', '~]|')('|', '|https?://|')())

###*
# GFM + Line Breaks Inline Grammar
###

inline.breaks = merge({}, inline.gfm,
    br: replace(inline.br)('{2,}', '*')()
    text: replace(inline.gfm.text)('{2,}', '*')())

###*
# Expose Inline Rules
###

InlineLexer.rules = inline

###*
# Static Lexing/Compiling Method
###

InlineLexer.output = (src, links, options) ->
    `var inline`
    inline = new InlineLexer(links, options)
    inline.output src

###*
# Lexing/Compiling
###

InlineLexer::output = (src) ->
    out = ''
    link = undefined
    text = undefined
    href = undefined
    cap = undefined
    while src
        # escape
        if cap = @rules.escape.exec(src)
            src = src.substring(cap[0].length)
            out += cap[1]

            continue
        # autolink
        if cap = @rules.autolink.exec(src)
            src = src.substring(cap[0].length)
            if cap[2] == '@'
                text = escape(if cap[1].charAt(6) == ':' then @mangle(cap[1].substring(7)) else @mangle(cap[1]))
                href = @mangle('mailto:') + text
            else
                text = escape(cap[1])
                href = text
            out += @renderer.link(href, null, text)

            continue
        # url (gfm)
        if !@inLink and (cap = @rules.url.exec(src))
            src = src.substring(cap[0].length)
            text = escape(cap[1])
            href = text
            out += @renderer.link(href, null, text)

            continue
        # tag
        if cap = @rules.tag.exec(src)
            if !@inLink and /^<a /i.test(cap[0])
                @inLink = true
            else if @inLink and /^<\/a>/i.test(cap[0])
                @inLink = false
            src = src.substring(cap[0].length)
            out += if @options.sanitize then (if @options.sanitizer then @options.sanitizer(cap[0]) else escape(cap[0])) else cap[0]

            continue
        # link
        if cap = @rules.link.exec(src)
            src = src.substring(cap[0].length)
            @inLink = true
            out += @outputLink(cap,
                href: cap[2]
                title: cap[3])
            @inLink = false

            continue
        # reflink, nolink
        if (cap = @rules.reflink.exec(src)) or (cap = @rules.nolink.exec(src))
            src = src.substring(cap[0].length)
            link = (cap[2] or cap[1]).replace(/\s+/g, ' ')
            link = @links[link.toLowerCase()]
            if !link or !link.href
                out += cap[0].charAt(0)
                src = cap[0].substring(1) + src

                continue
            @inLink = true
            out += @outputLink(cap, link)
            @inLink = false

            continue
        # u
        if cap = @rules.u.exec(src)
            src = src.substring(cap[0].length)
            out += @renderer.u(@output(cap[2] or cap[1]))
            continue
        # strong
        if cap = @rules.strong.exec(src)
            src = src.substring(cap[0].length)
            out += @renderer.strong(@output(cap[2] or cap[1]))
            continue
        # em
        if cap = @rules.em.exec(src)
            src = src.substring(cap[0].length)
            out += @renderer.em(@output(cap[2] or cap[1]))

            continue
        # code
        if cap = @rules.code.exec(src)
            src = src.substring(cap[0].length)
            out += @renderer.codespan(escape(cap[2].trim(), true))

            continue
        # br
        if cap = @rules.br.exec(src)
            src = src.substring(cap[0].length)
            out += @renderer.br()

            continue
        # del (gfm)
        if cap = @rules.del.exec(src)
            src = src.substring(cap[0].length)
            out += @renderer.del(@output(cap[1]))

            continue
        # text
        if cap = @rules.text.exec(src)
            src = src.substring(cap[0].length)
            out += @renderer.text(escape(@smartypants(cap[0])))

            continue
        if src
            throw new Error('Infinite loop on byte: ' + src.charCodeAt(0))
    out

###*
# Compile Link
###

InlineLexer::outputLink = (cap, link) ->
    href = escape(link.href)
    title = if link.title then escape(link.title) else null
    if cap[0].charAt(0) != '!' then @renderer.link(href, title, @output(cap[1])) else @renderer.image(href, title, escape(cap[1]))

###*
# Smartypants Transformations
###

InlineLexer::smartypants = (text) ->
    if !@options.smartypants
        return text
    text.replace(/---/g, '—').replace(/--/g, '–').replace(/(^|[-\u2014/(\[{"\s])'/g, '$1‘').replace(/'/g, '’').replace(/(^|[-\u2014/(\[{\u2018\s])"/g, '$1“').replace(/"/g, '”').replace /\.{3}/g, '…'

###*
# Mangle Links
###

InlineLexer::mangle = (text) ->
    if !@options.mangle
        return text
    out = ''
    l = text.length
    i = 0
    ch = undefined
    while i < l
        ch = text.charCodeAt(i)
        if Math.random() > 0.5
            ch = 'x' + ch.toString(16)
        out += '&#' + ch + ';'
        i++
    out

Renderer::code = (code, lang, escaped) ->
    if @options.highlight
        out = @options.highlight(code, lang)
        if out != null and out != code
            escaped = true
            code = out
    if !lang
        return '<pre><code>' + (if escaped then code else escape(code, true)) + '\n</code></pre>'
    '<pre><code class="' + @options.langPrefix + escape(lang, true) + '">' + (if escaped then code else escape(code, true)) + '\n</code></pre>\n'

Renderer::blockquote = (quote) ->
    '<blockquote>\n' + quote + '</blockquote>\n'

Renderer::html = (html) ->
    html

Renderer::heading = (text, level, raw) ->
    '<h' + level + ' id="' + @options.headerPrefix + raw.toLowerCase().replace(/[^\w]+/g, '-') + '">' + text + '</h' + level + '>\n'

Renderer::hr = ->
    if @options.xhtml then '<hr/>\n' else '<hr>\n'

Renderer::list = (body, ordered) ->
    type = if ordered then 'ol' else 'ul'
    '<' + type + '>\n' + body + '</' + type + '>\n'

Renderer::listitem = (text) ->
    '<li>' + text + '</li>\n'

Renderer::paragraph = (text) ->
    '<p>' + text + '</p>\n'

Renderer::table = (header, body) ->
    '<table>\n' + '<thead>\n' + header + '</thead>\n' + '<tbody>\n' + body + '</tbody>\n' + '</table>\n'

Renderer::tablerow = (content) ->
    '<tr>\n' + content + '</tr>\n'

Renderer::tablecell = (content, flags) ->
    type = if flags.header then 'th' else 'td'
    tag = if flags.align then '<' + type + ' style="text-align:' + flags.align + '">' else '<' + type + '>'
    tag + content + '</' + type + '>\n'

# span level renderer

_render_tag = (tag)->
    (txt)->
        """<#{tag}>#{txt}</#{tag}>"""

Renderer::strong = _render_tag('strong')
Renderer::em = _render_tag('em')
Renderer::u = _render_tag('u')
Renderer::del = _render_tag('del')

Renderer::codespan = _render_tag('code')

Renderer::br = ->
    if @options.xhtml then '<br/>' else '<br>'


Renderer::link = (href, title, text) ->
    if @options.sanitize
        try
            prot = decodeURIComponent(unescape(href)).replace(/[^\w:]/g, '').toLowerCase()
        catch e
            return ''
        if prot.indexOf('javascript:') == 0 or prot.indexOf('vbscript:') == 0 or prot.indexOf('data:') == 0
            return ''
    if @options.baseUrl and !originIndependentUrl.test(href)
        href = resolveUrl(@options.baseUrl, href)
    out = '<a href="' + href + '"'
    if title
        out += ' title="' + title + '"'
    out += '>' + text + '</a>'
    out

Renderer::image = (href, title, text) ->
    if @options.baseUrl and !originIndependentUrl.test(href)
        href = resolveUrl(@options.baseUrl, href)
    out = '<img src="' + href + '" alt="' + text + '"'
    if title
        out += ' title="' + title + '"'
    out += if @options.xhtml then '/>' else '>'
    out

Renderer::text = (text) ->
    text

###*
# Static Parse Method
###

Parser.parse = (src, options, renderer) ->
    parser = new Parser(options, renderer)
    parser.parse src

###*
# Parse Loop
###

Parser::parse = (src) ->
    @inline = new InlineLexer(src.links, @options, @renderer)
    @tokens = src.reverse()
    out = ''
    while @next()
        out += @tok()
    out

###*
# Next Token
###

Parser::next = ->
    @token = @tokens.pop()

###*
# Preview Next Token
###

Parser::peek = ->
    @tokens[@tokens.length - 1] or 0

###*
# Parse Text Tokens
###

Parser::parseText = ->
    body = @token.text
    while @peek().type == 'text'
        body += '\n' + @next().text
    @inline.output body

###*
# Parse Current Token
###

Parser::tok = ->
    switch @token.type
        when 'space'
            return ''
        when 'hr'
            return @renderer.hr()
        when 'heading'
            return @renderer.heading(@inline.output(@token.text), @token.depth, @token.text)
        when 'code'
            return @renderer.code(@token.text, @token.lang, @token.escaped)
        when 'table'
            header = ''
            body = ''
            row = undefined
            cell = undefined
            flags = undefined
            j = undefined
            # header
            cell = ''
            i = 0
            while i < @token.header.length
                flags =
                    header: true
                    align: @token.align[i]
                cell += @renderer.tablecell(@inline.output(@token.header[i]),
                    header: true
                    align: @token.align[i])
                i++
            header += @renderer.tablerow(cell)
            i = 0
            while i < @token.cells.length
                row = @token.cells[i]
                cell = ''
                j = 0
                while j < row.length
                    cell += @renderer.tablecell(@inline.output(row[j]),
                        header: false
                        align: @token.align[j])
                    j++
                body += @renderer.tablerow(cell)
                i++
            return @renderer.table(header, body)
        when 'blockquote_start'
            body = ''
            while @next().type != 'blockquote_end'
                body += @tok()
            return @renderer.blockquote(body)
        when 'list_start'
            body = ''
            ordered = @token.ordered
            while @next().type != 'list_end'
                body += @tok()
            return @renderer.list(body, ordered)
        when 'list_item_start'
            body = ''
            while @next().type != 'list_item_end'
                body += if @token.type == 'text' then @parseText() else @tok()
            return @renderer.listitem(body)
        when 'loose_item_start'
            body = ''
            while @next().type != 'list_item_end'
                body += @tok()
            return @renderer.listitem(body)
        when 'html'
            html = if !@token.pre and !@options.pedantic then @inline.output(@token.text) else @token.text
            return @renderer.html(html)
        when 'paragraph'
            return @renderer.paragraph(@inline.output(@token.text))
        when 'text'
            return @renderer.paragraph(@parseText())
    return

baseUrls = {}
originIndependentUrl = /^$|^[a-z][a-z0-9+.-]*:|^[?#]/i
noop.exec = noop

###*
# Options
###

marked.options =
marked.setOptions = (opt) ->
    merge marked.defaults, opt
    marked

marked.defaults =
    gfm: true
    tables: true
    breaks: false
    pedantic: false
    sanitize: false
    sanitizer: null
    mangle: true
    smartLists: false
    silent: false
    highlight: null
    langPrefix: 'lang-'
    smartypants: false
    headerPrefix: ''
    renderer: new Renderer
    xhtml: false
    baseUrl: null

###*
# Expose
###

marked.Parser = Parser
marked.parser = Parser.parse
marked.Renderer = Renderer
marked.Lexer = Lexer
marked.lexer = Lexer.lex
marked.InlineLexer = InlineLexer
marked.inlineLexer = InlineLexer.output
marked.parse = marked

module.exports = marked
