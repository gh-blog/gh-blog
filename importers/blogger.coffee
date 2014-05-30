cheerio = require 'cheerio'
html_md = require 'html-md'
fs      = require 'fs'
_       = require 'lodash'
moment  = require 'moment'

class Importer
    constructor: (@xml, options) ->

        @options = _.defaults options,
            downloadImages: no

        $ = cheerio.load @xml, decodeEntities: yes, xmlMode: yes

        entries = $('entry').filter ->
            schema = $(this).find('category').attr('term')
            schema.match new RegExp 'http://schemas.google.com/blogger/\\d+/kind#post/?', 'gi'

        posts = entries.map ->
            post = $ this
            published = new Date post.find('published').text()
            updated = new Date post.find('updated').text() || null
            title = post.find('title').text()
            html = "<h1>#{title}</h1>\n" + post.find('content').text()
            images = $(html).find('gd:image').attr('src')
            markdown = html_md html, inline: yes
            _url = post.find('link[rel="replies"]').attr('href')
            _url = _url.match /(^.+\/([^\/]+)\.html)?#comment-form$/i
            url = _url[1]
            id = _url[2]

            { id, title, published, updated, url, images, markdown, html }

        @posts = posts.get()


module.exports = Importer