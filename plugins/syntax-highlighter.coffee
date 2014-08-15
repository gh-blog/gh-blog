through2 = require 'through2'
{ highlight, highlightAuto } = require 'highlight.js'

module.exports = (options) ->
    processFile = (file, enc, done) ->
        { $ } = file
        $('pre code').each (i, block) ->
            $block = $(block)
            lang = $block.attr('class').match(/lang-(\S*)/i)?[1]
            code = $block.text()
            if lang
                code = highlight(lang, code, yes).value
            else
                code = highlightAuto(code, yes).value
            $block.html code

        file.contents = new Buffer $.html()
        done null, file

    through2.obj processFile