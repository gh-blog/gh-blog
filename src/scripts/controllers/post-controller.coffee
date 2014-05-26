module.exports = [
    '$rootScope', '$scope', '$log', '$routeParams', 'ContentService', '$timeout',
    ($rootScope, $scope, $log, $routeParams, ContentService, $timeout) ->
        $rootScope.state = 'loading'
        $scope.post = $routeParams
        $log.debug '$routeParams', $scope.post

        # $timeout ->
        ContentService.getPost $routeParams.id, $routeParams.page
        .then (post) ->
            $scope.post = post
            $rootScope.state = 'ready'
            $log.debug 'Post loaded', post
        .catch (err) ->
            $rootScope.error = err
            $rootScope.state = 'error'
            $log.debug 'Error', err

        $log.debug 'Post Controller ready'
]