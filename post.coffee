fs              = require 'fs'
q               = require 'q'
cheerio         = require 'cheerio'
path            = require 'path'
changeCase      = require 'change-case'
marked          = require 'marked'
thumbbot        = require 'thumbbot'

class Post
    regex = /(\d{4}\-\d{2}\-\d{2})\-(.+)\.md/i
    constructor: (file) ->
        markdown = fs.readFileSync(file.path).toString()
        html = marked markdown
        $ = cheerio.load html
        video = ->
            $(this).is('video') or
            (
                $(this).is('a') and
                $(this).attr('href').match /youtube.com\/watch\?v=[a-zA-Z0-9-]{10}/gi
            )
        video = 'video, a[href*="youtube.com"]'
        audio = 'audio, a[href*="soundcloud.com/"]'
        image = 'img, picture, figure'
        link = ->
            $(this).is('a') and
            not $(this).is(video) and
            not $(this).is(audio) and
            not $(this).is(image)

        @title = $('h1').text().trim() || null
        @filename = path.basename file.path
        @id = @filename.match(regex)[2] || changeCase.paramCase @title
        @date = new Date(@filename.match(regex)[1])
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


module.exports = Post