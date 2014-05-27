_ = require 'lodash'
module.exports = [
    '$http', '$rootScope', 'CacheService', '$q', '$sce', '$log',
    ($http, $rootScope, CacheService, $q, $sce, $log) ->
        $log.debug 'Content Service ready'
        getBlog: ->
            fn = =>
                $http.get 'config.json', cache: yes
                .then (res) -> $rootScope.blog = res.data
            CacheService.get 'blog', 'blog', fn
        getPage: (page = 1) ->
            fn = =>
                @getBlog()
                .then ->
                    $http.get "content/posts.#{page}.json", cache: yes
                .then (res) ->
                    _.map res.data, (post, i, collection) ->
                        _.extend post,
                            url: "#{page}/#{post.id}"
                            next: try collection[i + 1].id
                            prev: try collection[i - 1].id
            CacheService.get 'pages', page, fn
        getPost: (id, page = 1) ->
            fn = =>
                @getPage(page).then (posts) ->
                    post = _.findWhere posts, id: id
                    if typeof post is 'undefined'
                        throw new Error 'POST_NOT_FOUND'
                    else
                        $http.get "content/#{post.filename}", cache: yes
                        .then (fullText) ->
                            _.extend post, html: $sce.trustAsHtml fullText.data
            CacheService.get 'posts', id, fn
]