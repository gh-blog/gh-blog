through2 = require 'through2'
{ guessDir, isRTL, isLTR } = require '../utils'

module.exports = (options = { defaults: { } }) ->
    processFile = (file, enc, done) ->
        # @TODO @FIXME get rid of this
        file.type = 'text'

        file.isPost = yes
        if file.$
            { $ } = file
            getTextDir = (fallback) ->
                text = $.root().clone().remove('pre').text()
                guessDir text, fallback

            isDescriptive = (i, paragraph) ->
                $paragraph = $ paragraph
                $paragraph.text().trim().match /\.$/gi

            file.title = $('h1').first().text().trim()
            file.image = $('img').first().attr('src') || null
            file.excerpt =
                $('p').filter(isDescriptive)
                .html()

            file.dir = getTextDir 'ltr' if not file.dir

        for key, value of options.defaults
            if not file.hasOwnProperty key
                file[key] = value

        done null, file

    through2.obj processFile