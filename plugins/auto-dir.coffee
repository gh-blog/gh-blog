through2 = require 'through2'
{ isRTL } = require '../utils'

module.exports = (options) ->
    processFile = (file, enc, done) ->
        { $ } = file

        $('code').each (i, el) ->
            $el = $(el)
            $el.attr 'dir', 'ltr'
            $el.attr 'lang', 'en'

        $('pre code').each (i, block) ->
            $block = $(block)
            $block.attr 'lang', 'en'
            $block.parent('pre').attr 'dir', 'ltr'
            $block.find('.hljs-comment').each (i, comment) ->
                $comment = $(comment)
                $comment.attr 'dir', 'rtl' if isRTL $comment.text()


        file.contents = new Buffer $.html()
        done null, file

    through2.obj processFile