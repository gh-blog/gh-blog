module.exports = [
    '$rootScope', '$scope', '$log', '$routeParams', 'ContentService',
    ($rootScope, $scope, $log, $routeParams, ContentService) ->
        $rootScope.state = 'loading'
        ContentService.getPost $routeParams.slug
        .then (post) ->
            $scope.post = post
            $rootScope.state = 'ready'
            $log.debug "Post", post
        $log.debug 'Post Controller ready'
]