angular = require 'angular'
module.exports = [
    '$http', '$rootScope', 'CacheService', '$q', '$sce', '$log',
    ($http, $rootScope, CacheService, $q, $sce, $log) ->

        $log.debug 'Content Service ready'

        service =
            blog: ->
                $http.get 'config.json', cache: yes
                .then (response) ->
                    config = response.data
                    $rootScope.blog = config
                    config

            page: (page) ->
                $http.get "content/posts.#{page}.json", cache: yes
                .then (res) ->
                    res.data.map (post, i, collection) ->
                        angular.extend post,
                            url: post.id
                            next: try collection[i + 1].id
                            prev: try collection[i - 1].id

            post: (id) ->
                $http.get "content/#{id}.json", cache: yes
                .then (response) ->
                    post = response.data
                    post.html = $sce.trustAsHtml post.html
                    post

        get: (query = { blog: null }) ->
            key = Object.keys(query)[0].toLowerCase()
            val = query[key]
            fn = ->
                service[key] val

            CacheService.get 'blog', "#{key}:#{val}", fn
]