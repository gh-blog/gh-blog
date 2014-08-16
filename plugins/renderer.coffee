utils = require '../utils'

cheerio = require 'cheerio'
{ Renderer } = require 'marked'

renderer = new Renderer

renderer.image = (href, title, text) ->
    # @TODO: check if file exists in image directory
    href = "/content/images/#{href}" if not href.match /^((f|ht)tps)|(www):/i
    "
    <span class='media-container'>
        <img src='#{href}' '#{title ? title : ''}' text='#{text}'/>
    </span>
    "
renderer.codespan = (code) ->
    "<code dir='ltr'>#{code}</code>"

module.exports = renderer