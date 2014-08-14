module.exports = [
    'momentFilter', '$interval', '$log',
    (momentFilter, $interval, $log) ->
        transclude: no

        scope:
            date: '@timeAgo'

        template: '
            <abbr title="{{ fullDate }}">
                <time datetime="{{ date.toJSON() }}">
                    {{ timeAgo }}
                </time>
            </abbr>
        '
        link: ($scope) ->
            $scope.timeAgo = momentFilter $scope.date
            $scope.fullDate = momentFilter $scope.date, 'LL'
]