class MissingPluginError extends Error
    constructor: (@feature, @requiredBy, args...) -> super args...
    requiredBy: []
    toString: ->
        "Feature #{@feature} is required by #{@requiredBy.join ', '}
        but is not provided by any plugin."

class UnknownTypeError extends TypeError
    constructor: (@type, args...) -> super args...
    toString: ->
        "Features of type #{@type} are unrecognizable."

class ManifestError extends Error
    constructor: (@code, @fileName, originalError) ->
        @name = 'ManifestError'
        @message = switch code
            when 'MALFORMED_JSON'
                'Manifest data must be valid JSON'

            when 'CIRCULAR_DEPENDENCY'
                'Plugins can not require features they already provide'

            when 'DEPENDENCY_CONFLICT'
                'A feature may either be required or recommended, not both'

            when 'MALFORMED_MANIFEST_ROOT'
                '"gh-blog" entry must be a JSON object'

            when 'MISSING_MANIFEST_ENTRY'
                '"gh-blog" must have a "provides" entry'

            when 'MALFORMED_MANIFEST_ENTRY'
                'All "gh-blog" entries must be valid JSON arrays and contain
                at least one string'

            else originalError.message

        @lineNumber = originalError.lineNumber
        @columnNumber = originalError.columnNumber
        super code

    toString: -> "#{@name} [#{@code}] in #{@fileName}: #{@message}"

module.exports = { ManifestError, UnknownTypeError, MissingPluginError }