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

# renderer.code = (code, lang) ->
#     html =
#         if lang
#             highlight.highlight(lang, code, yes).value
#         else
#             highlight.highlightAuto(code, yes).value

#     $$ = cheerio.load html

#     ($$ '.hljs-comment').each ->
#         $this = $$(this)
#         if utils.isRTL $this.text()
#             $this.attr('dir', 'rtl').attr('lang', 'ar')
#         else $this.attr 'dir', 'ltr'

#     "<pre lang='en'>#{$$.html()}</pre>"

renderer.codespan = (code) ->
    "<code dir='ltr'>#{code}</code>"

module.exports = renderer