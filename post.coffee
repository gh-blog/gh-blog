fs              = require 'fs'
async           = require 'async'
cheerio         = require 'cheerio'
path            = require 'path'
changeCase      = require 'change-case'
marked          = require 'marked'
thumbbot        = require 'thumbbot'
highlight       = require 'highlight.js'

_               = require 'lodash'

renderer        = new marked.Renderer()

through2        = require 'through2'
File            = require('gulp-util').File
EventEmitter    = require('events').EventEmitter

utils = require './utils'

request  = require 'request'

{ api_key }  = require './secret.json'

renderer.image = (href, title, text) ->
    # TODO: check if file exists in image directory
    href = "/content/images/#{href}" if not href.match /^((f|ht)tps)|(www):/i
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
        if utils.isRTL $this.text()
            $this.attr('dir', 'rtl').attr('lang', 'ar')
        else $this.attr 'dir', 'ltr'

    "<pre lang='en'>#{$$.html()}</pre>"

renderer.codespan = (code) ->
    "<code dir='ltr'>#{code}</code>"

marked.setOptions
    renderer: renderer

class Post
    regex = /(\d{4}\-\d{2}\-\d{2})\-(.+)\.(md|markdown)/i
    constructor: (@file, @config) ->

    load: (done) ->
        markdown = @file.contents.toString()
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

        embeddable = ->
            $this = $ this
            url = $this.attr('href') || $this.attr('src')
            if not url.match /^\/.+/gi
                $this.data 'url', url
                yes
            else no

        @title = $('h1').first().text().trim() || null
        @filename = path.basename @file.path
        @id = @filename.match(regex)[2] || changeCase.paramCase @title
        @date = new Date(@filename.match(regex)[1])
        @filename = "#{@id}.json"
        @image = $('img').first().attr('src') || null

        for i, child of $('p').toArray() when not @excerpt
            @excerpt = $(child).text().trim()

        parent = $('p:first-child')
        first = parent.find('> *').first()

        $images = $('*').filter(image).toArray()
        $videos = $('*').filter(video).toArray()
        $tracks = $('*').filter(audio).toArray()
        $links = $('*').filter(link).toArray()

        embeddable = $(block).filter(embeddable) for block in _.flatten [$images, $videos, $tracks]

        @images = $images.length
        @videos = $videos.length
        @tracks = $tracks.length
        @links = $links.length

        @type =
            switch
                when first
                    .is(video) then 'video'
                when first.is(audio) then 'audio'
                when first.is(image) and
                    not $('h2, h3, h4, h5, h6').length then 'image'
                when parent.text().trim() is first.text().trim() and first.is(link) then 'link'
                else 'text'

        @url = "/content/#{@id}.html"
        @dateFormatted = utils.formatDate @date, @config.locale.language, @config.locale.dateFormat

        async.each embeddable, (block, callback) ->
            $block = $ block
            url = $block.data 'url'
            console.log 'embeddable!', url
            request {
                uri: "http://iframe.ly/api/oembed?url=#{url}&api_key=#{api_key}"
            }, (err, res) ->
                if err then return callback()
                body = JSON.parse res.body
                $block.html body.html
                console.log 'Found embeddable block:', body.html
                callback()
        , (err) =>
            if err then console.log err.toString()
            @html = $.html()
            done()
        # @emit 'end'

module.exports = (options) ->
    post = { }

    process = (file, enc, callback) ->
        post = new Post file, options
        post.load =>
            @emit 'post', post
            file = new File()
            file.contents = new Buffer JSON.stringify _.pick post, [
                'id', 'filename', 'type', 'url', 'date', 'dateFormatted'
                'images', 'tracks', 'links', 'videos', 'html'
            ]
            file.path = post.filename
            callback null, file

    through2.obj process