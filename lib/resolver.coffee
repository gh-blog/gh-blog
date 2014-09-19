fs = require 'fs'
path = require 'path'
glob = require 'glob'
_ = require 'lodash'

Errors = require './errors'
{ validate } = require './manifest'

topsort = require 'topsort'

class Resolver
    _types = ['requires', 'recommends', 'provides']
    @ENUM_TYPES = ENUM_TYPES = {
        required: 'requires'
        recommended: 'recommends'
        installed: 'provides'
        provided: 'provides'
        available: 'provides'
        missing: 'missing'
    }

    constructor: (@cwd = process.cwd()) ->
        # Get manifest files
        @files =
            glob.sync "./*/package.json", { cwd }
            .map (file) -> path.resolve cwd, file

        # Read manifests and assign
        provided = []
        @manifests = { }
        for filename in @files
            _manifest = JSON.parse String fs.readFileSync filename
            validate _manifest, filename
            manifest = _manifest["gh-blog"]
            manifest.name = _manifest.name
            provided = Array::concat provided, manifest.provides
            manifest.recommends = _.reject manifest.recommends, (feature) => not _.contains provided, feature
            manifest.requires = Array::concat (manifest.requires || []), (manifest.recommends || [])
            delete manifest.requires if not manifest.requires.length
            @manifests[_manifest.name] = manifest


    get_tasks_ordered: ->
        deps = []
        for key, manifest of @manifests
            sub_deps =
                _.chain(@manifests).filter (m) ->
                    _.some m.provides, (feature) ->
                        _.contains(manifest.requires, feature) or
                        _.contains(manifest.recommends, feature)
                .map (a) -> a.name
                .value()
            sub_deps.unshift key
            deps.unshift sub_deps

        return topsort(deps).reverse()


    features: (type, forWhich) ->
        if not ENUM_TYPES[type]
            throw new Errors.UnknownTypeError type

        type = ENUM_TYPES[type]

        results = { }
        if type is 'missing'
            available = @features 'available', forWhich
            required = @features 'required', forWhich
            for feature, plugin of required
                if not available[feature]
                    results[feature] = plugin
        else
            if not forWhich
                _manifests = @manifests
            else if (_.isArray forWhich) or typeof forWhich is 'string'
                _manifests = _.pick @manifests, forWhich
            else
                throw new TypeError

            for name, props of _manifests
                if props[type]
                    for feature in props[type]
                        results[feature] = Array::concat (results[feature] || []), name
        return results

module.exports = Resolver