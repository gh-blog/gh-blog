cheerio      = require 'cheerio'
html_md      = require 'html-md'
fs           = require 'fs'
_            = require 'lodash'
moment       = require 'moment'
http         = require 'http'
through      = require 'through'
gutil        = require 'gulp-util'
File         = gutil.File

class Importer
    constructor: (options) ->
        options = _.defaults options,
            images: no
            html: no

        posts = []

        process = (xmlFile) ->
            self = @
            xml = xmlFile.contents.toString()
            $ = cheerio.load xml, decodeEntities: yes, xmlMode: yes

            entries = $('entry').filter ->
                schema = $(this).find('category').attr('term')
                schema.match new RegExp 'http://schemas.google.com/blogger/\\d+/kind#post/?', 'gi'

            posts = entries.map ->
                post = $ this
                published = new Date post.find('published').text()
                updated = new Date post.find('updated').text() || null
                title = post.find('title').text()
                html = "<h1>#{title}</h1>\n" + post.find('content').text()
                $html = cheerio.load html

                images = $html('img').map ->
                    $(this).attr('src')
                .get()


                if options.images
                    images.forEach (url) -> if url then self.emit 'image', url
                    $html('img').each ->
                        img = $(this)
                        old_src = img.attr('src')
                        new_src = old_src.match(/^.+\/([^\/]+)$/i)[1]
                        img.attr('src', new_src)
                        anchor = img.closest("a[href*='#{new_src}']")
                        anchor.replaceWith img


                html = $html.html()

                markdown = html_md html, inline: yes

                href = post.find('link[rel="replies"]').attr('href')
                href = href.match /(^.+\/([^\/]+)\.html)?#comment-form$/i

                url = href[1]
                id = href[2]

                date = moment(published).format 'YYYY-MM-DD'

                post = { id, title, published, updated, url, images, markdown, html }

                self.emit 'post', post

                ext = if options.html then 'html' else 'md'

                self.emit 'data', new File
                    path: "#{date}-#{post.id}.#{ext}"
                    contents: new Buffer if options.html then post.html else post.markdown

            .get()

        endStream = ->
            @emit 'end', posts

        return through process, endStream

module.exports = Importer