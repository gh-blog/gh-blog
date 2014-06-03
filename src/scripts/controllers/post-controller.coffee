module.exports = [
    '$rootScope', '$scope', '$log', '$routeParams', 'ContentService', '$timeout',
    ($rootScope, $scope, $log, $routeParams, ContentService, $timeout) ->
        $rootScope.state = 'loading'
        $scope.post = $routeParams
        $log.debug '$routeParams', $scope.post

        # $timeout ->
        ContentService.get post: $routeParams.id
        .then (post) ->
            $scope.post = post
            $scope.title = post.title
            $rootScope.state = 'ready'
            $log.debug 'Post loaded', post
        .catch (err) ->
            $scope.error = err
            $rootScope.state = 'error'
            $log.debug 'Error', err

        $log.debug 'Post Controller ready'
]