path = require 'path'
through2 = require 'through2'
git = require 'git-promise'
Promise = require 'promise'

module.exports = (repo) ->
    if typeof repo isnt 'string'
        throw new TypeError 'You must specify a path to git
        repository to extract metadata from'

    strToDate = (str) ->
        return new Date str if str
        null

    processFile = (file, enc, done) ->
        filename = file.basename || path.basename file.path

        dateAdded =
            git "git log -1 --pretty=format:'%cd' --diff-filter=A #{filename}", cwd: repo
            .then strToDate

        dateModified =
            git "git log -1 --pretty=format:'%cd' --diff-filter=M #{filename}", cwd: repo
            .then strToDate

        Promise.all [dateAdded, dateModified]
        .then (dates) ->
            # @TODO: format dates with moment.js
            if dates[0]
                file.dateAdded = dates[0]
                file.dateAddedFormatted = dates[0].toString()
            if dates[1]
                file.dateModified = dates[1]
                file.dateModifiedFormatted = dates[1].toString()
            done null, file
        .catch (err) ->
            # @TODO: debug
            console.log 'Error in metadata', err
            throw err

    through2.obj processFile