fs              = require 'fs'
q               = require 'q'
cheerio         = require 'cheerio'
path            = require 'path'
changeCase      = require 'change-case'
marked          = require 'marked'
thumbbot        = require 'thumbbot'
highlight       = require 'highlight.js'

renderer        = new marked.Renderer()

through         = require 'through'
File            = require('gulp-util').File

isRTL           = require('./utils').isRTL

renderer.image = (href, title, text) ->
    # TODO: check if file exists in image directory
    href = "content/images/#{href}" if not href.match /^((f|ht)tps)|(www):/i
    # TODO: Remove null attributes
    "
    <span class='media-container'>
        <img src='#{href}' '#{title ? title : ''}' text='#{text}'/>
    </span>
    "

renderer.code = (code, lang) ->

    html =
        if lang
            highlight.highlight(lang, code, yes).value
        else
            highlight.highlightAuto(code, yes).value

    $$ = cheerio.load html

    ($$ '.hljs-comment').each ->
        $this = $$(this)
        if isRTL $this.text()
            $this.attr('dir', 'rtl').attr('lang', 'ar')
        else $this.attr 'dir', 'ltr'

    "<pre lang='en'>#{$$.html()}</pre>"

renderer.codespan = (code) ->
    "<code dir='ltr'>#{code}</code>"

marked.setOptions
    renderer: renderer

class Post
    regex = /(\d{4}\-\d{2}\-\d{2})\-(.+)\.(md|markdown)/i
    constructor: (file) ->
        markdown = file.contents.toString()
        @html = marked markdown
        $ = cheerio.load @html
        video = ->
            $(this).is('video') or
            (
                $(this).is('a') and
                $(this).attr('href').match /youtube.com\/watch\?v=[a-zA-Z0-9-]{10}/gi
            )
        audio = 'audio, a[href*="soundcloud.com/"]'
        image = 'img, picture, figure'
        link = ->
            $(this).is('a') and
            not $(this).is(video) and
            not $(this).is(audio) and
            not $(this).is(image)

        @title = $('h1').first().text().trim() || null
        @filename = path.basename file.path
        @id = @filename.match(regex)[2] || changeCase.paramCase @title
        @date = new Date(@filename.match(regex)[1])
        @filename = "#{@id}.json"
        @image = $('img').first().attr('src') || null

        for i, child of $('p').toArray() when not @description
            @description = $(child).text().trim()

        parent = $('p:first-child')
        first = parent.find('> *').first()
        @images = $('*').filter(image).length
        @videos = $('*').filter(video).length
        @tracks = $('*').filter(audio).length
        @links = $('*').filter(link).length
        @type =
            switch
                when first
                    .is(video) then 'video'
                when first.is(audio) then 'audio'
                when first.is(image) and
                    not $('h2, h3, h4, h5, h6').toArray().length then 'image'
                when parent.text().trim() is first.text().trim() and first.is(link) then 'link'
                else 'text'

module.exports = (options) ->
    post = { }

    process = (file) ->
        post = new Post file
        @emit 'post', post
        @emit 'data', new File
            contents: new Buffer JSON.stringify post
            path: post.filename

    endStream = ->
        @emit 'end'

    through process, endStream