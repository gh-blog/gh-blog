marked = require 'marked'
highlight = require 'highlight.js'

marked.setOptions
  highlight: (code, lang) ->
    highlight.highlightAuto(code).value

module.exports = [
    'CacheService', '$q', '$log',
    (CacheService, $q, $log) ->
        replace: yes
        link: ($scope, $element, $attrs) ->
            w = $scope.$watch 'post', (post) ->
                try
                    fn = ->
                        deferred = $q.defer()
                        marked post.text, (err, md) ->
                            if err then deferred.reject err
                            else deferred.resolve md
                        deferred.promise

                    CacheService.get 'html', post.slug, fn
                    .then (markdown) ->
                        $element.html markdown
                        w()
]