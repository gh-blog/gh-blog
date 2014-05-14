_ = require 'lodash'
module.exports = [
    '$http', '$cacheFactory', '$log',
    ($http, $cacheFactory, $log) ->
        cache = $cacheFactory()
        posts = undefined
        $log.debug 'Content Service ready'
        get: ->
            posts = $http.get 'content/posts.json', cache: yes
            .then (res) ->
                _.map res.data, (post) ->
                    post.url = "posts/#{post.slug}"
                    post
        getPost: (slug) ->
            cached = cache.get slug
            if not cached
                post = undefined
                promise = (posts || @get()).then (posts) ->
                    post = _.findWhere posts, slug: slug
                    $http.get "content/#{post.filename}", cache: yes
                .then (res) ->
                    _.chain post
                    .extend text: res.data
                    .value()
                cache.put slug, promise
                promise
            else cached
]