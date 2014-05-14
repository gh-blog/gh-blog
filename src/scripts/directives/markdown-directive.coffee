marked = require 'marked'
highlight = require 'highlight.js'

marked.setOptions
  highlight: (code) ->
    highlight.highlightAuto(code).value

cache = []

module.exports = [
    '$timeout', '$log',
    ($timeout, $log) ->
        replace: yes
        link: ($scope, $element, $attrs) ->
            w = $scope.$watch 'post', (post) ->
                try
                    $element.html cache[post.slug] ||
                        cache[post.slug] = marked post.text
                    w()
]