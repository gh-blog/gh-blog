# Code from sparkalow/angular-infinite-scroll
module.exports = [
    '$window', '$timeout', '$log',
    ($window, $timeout, $log) ->
        priority: 500
        link: ($scope, $element, $attrs) ->
            offset = parseInt($attrs.threshold) || 0
            e = $element[0]
            angular.element($window).bind 'scroll', ->
                # $log.debug 'Scrolling...'
                if $scope.$eval($attrs.canLoad) and e.scrollTop + e.offsetHeight >= e.scrollHeight - offset
                    $scope.$apply $attrs.infiniteScroll
]