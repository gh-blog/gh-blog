through2 = require 'through2'

module.exports = (options) ->
    processFile = (file, enc, done) ->
        for key, value of options
            if not file.hasOwnProperty key
                file[key] = value

        # @TODO @FIXME get rid of those
        file.dateFormatted = 'whatver'
        file.type = 'text'
        file.dir = 'rtl'
        done null, file

    through2.obj processFile