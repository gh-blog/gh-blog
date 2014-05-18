module.exports = [
    '$http', '$cacheFactory', '$q', '$log',
    ($http, $cacheFactory, $q, $log) ->
        get: (cacheId, entryId, fallback, options) ->
            cache = $cacheFactory.get(cacheId) || $cacheFactory(cacheId, options)
            cached = cache.get entryId
            if cached then cached else fallback()
]