_   = require 'lodash'
git = require 'git-promise'
{ File }   = require 'gulp-util'
through2 = require 'through2'
path = require 'path'

toSpaceSeparated = (str) ->
    if typeof str is 'string'
        str
    else if _.isArray str
        ("\"#{el}\"" for el in str).join(' ')
    else throw new TypeError 'The specified parameter is neither
    a string nor an array'

states =
    '  ' : 'unmodified'
    ' M' : 'modified'
    ' A' : 'added'
    ' R' : 'renamed'
    ' C' : 'copied'
    ' D' : 'deleted'
    '??': 'untracked'
    '!!': 'ignored'


strToArray = (str) ->
    str.split('\n').filter (line) ->
        line.length

arrayToObjects = (command) ->
    (lines) ->
        all = []
        lines.map (line) ->
            console.log "LINE #{line}"
            m = line.match /^(.*)\s(.*)/i
            status = states[m[1]]
            filename = m[2]
            { filename, status }

objectsToFiles = (objects) ->
    objects.map (obj) ->
        file = new File path: obj.filename
        file.status = obj.status
        file

status = (options = { cwd: null }) ->
    { cwd, filter } = options

    if not cwd
        throw new Error 'You must specifiy a working directory'

    processFile = (file, enc, done) ->
        promise.then (files) =>
            i = _.findIndex files, { path: file.path }
            file = files[i] if i > -1
            if not file.status
                # File did not show up in git status,
                # so we assume it was not modified
                file.status = states['  ']
            done null, file
            files

    cmd='git status --porcelain --untracked-files="all"'
    promise =
        git cmd, cwd: cwd
        .then strToArray
        .then arrayToObjects cmd
        .then objectsToFiles
        .then (files) ->
            files.map (file) ->
                file.path = path.resolve cwd, file.path
                file

    through2.obj processFile

module.exports = { status }