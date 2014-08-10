module.exports = [
    '$rootScope', '$scope', '$log', '$routeParams', 'ContentService', '$timeout',
    ($rootScope, $scope, $log, $routeParams, ContentService, $timeout) ->

        $rootScope.state = 'loading'
        try delete $rootScope.error

        $scope.post = $routeParams
        $log.debug '$routeParams', $scope.post

        # $timeout ->
        ContentService.get()
        .then () ->
            ContentService.get post: $routeParams.id
        .then (post) ->

            $scope.post = post
            $rootScope.title = "#{post.title}"
            $rootScope.state = 'ready'
            $scope.state = 'ready'
            try delete $rootScope.error
            $log.debug 'Post loaded', post

        .catch (err) ->
            $rootScope.error = err
            $rootScope.state = 'error'
            $log.debug 'Error', err

        $log.debug 'Post Controller ready'
]