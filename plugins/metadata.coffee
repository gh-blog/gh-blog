through2 = require 'through2'

module.exports = (options = { defaults: { } }) ->
    processFile = (file, enc, done) ->
        for key, value of options.defaults
            if not file.hasOwnProperty key
                file[key] = value

        # @TODO @FIXME get rid of those
        file.dateFormatted = 'whatver'
        file.type = 'text'
        file.dir = 'rtl'

        file.isPost = yes
        if file.$
            { $ } = file
            isDescriptive = (i, paragraph) ->
                $paragraph = $ paragraph
                $paragraph.text().trim().match /\.$/gi

            file.title = $('h1').first().text().trim()
            file.image = $('img').first().attr('src') || null
            file.excerpt =
                $('p').filter(isDescriptive)
                .html()

        done null, file

    through2.obj processFile