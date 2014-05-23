module.exports = [
    '$scope', '$log', '$routeParams', 'ContentService',
    ($scope, $log, $routeParams, ContentService) ->
        $scope.state = 'loading'
        $scope.post = $routeParams
        $log.debug '$routeParams', $scope.post
        ContentService.getPost $routeParams.id
        .then (post) ->
            $scope.post = post
            $scope.state = 'ready'
            $log.debug 'Post loaded', post
        $log.debug 'Post Controller ready'
]