through2 = require 'through2'
_ = require 'lodash'
{ isRTL } = require '../utils'
{ compileFile } = require 'jade'

module.exports = (options = { pretty: yes }) ->
    processFile = (file, enc, done) ->
        # @TODO expect file.localeString
        # @TODO expect file.title, ...
        try
            if file.isPost
                templateFile = 'post'
            else templateFile = 'index'
            templateFile = "#{__dirname}/templates/#{templateFile}.jade"

            renderFn = compileFile templateFile, options

            locals = _.clone file, yes
            # @TODO: get rid of those
            locals.styles = []
            locals.scripts = []
            locals.icons = []
            locals.manifest = ''
            locals.id = 'dfasdfasdf'
            locals.disqus = shortname: 'forabi'
            locals.language = 'ar'
            locals.html = String file.contents

            html = renderFn locals
            file.contents = new Buffer html
            done null, file
        catch e
            console.log 'error!!!', e
            done e, file

    through2.obj processFile