module.exports = [
    '$rootScope', '$scope', '$log', '$routeParams', 'ContentService', '$timeout',
    ($rootScope, $scope, $log, $routeParams, ContentService, $timeout) ->
        $rootScope.state = 'loading'
        $timeout ->
            $scope.post = $routeParams
            $log.debug '$routeParams', $scope.post

        $timeout ->
            ContentService.getPost $routeParams.id, $routeParams.page
            .then (post) ->
                $scope.post = post
                $rootScope.state = 'ready'
                $log.debug 'Post loaded', post
        $log.debug 'Post Controller ready'
]