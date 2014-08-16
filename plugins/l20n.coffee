fs = require 'fs'
{ Parser, Compiler } = require 'l20n'

through2 = require 'through2'

module.exports = (localeFile, localeCode='en') ->
    parser = new Parser
    compiler = new Compiler
    localeFileContent = fs.readFileSync(localeFile)

    compile = ->
        code = localeFileContent.toString();
        ast = parser.parse code
        compiler.compile ast

    processFile = (file, enc, done) ->
        try
            entries = compile localeFile
            results = { }
            for key, entry of entries
                if !entry.expression
                    results[key] = entry.getString file

            file.strings = results
            done null, file
        catch e
            done e, file

    through2.obj processFile