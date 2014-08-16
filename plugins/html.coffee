path = require 'path'
through2 = require 'through2'
marked = require 'marked'
cheerio = require 'cheerio'
renderer = require './renderer'

module.exports = (options) ->
    processFile = (file, enc, done) ->
        md = file.contents.toString()

        marked.setOptions { renderer }
        html = marked md

        file.$ = cheerio.load html
        file.isPost = yes
        file.contents = new Buffer html
        oldExtname = path.extname file.path
        file.path = file.path.replace (new RegExp "#{oldExtname}$"), '.html'
        done null, file

    through2.obj processFile