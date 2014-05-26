module.exports = [
    '$rootScope', '$scope', '$q', 'ContentService', '$routeParams', '$log'
    ($rootScope, $scope, $q, ContentService, $routeParams, $log) ->
        $rootScope.posts = []
        $rootScope.state = 'loading'
        $scope.load = (page = 1) ->
            $rootScope.state = 'loading'
            ContentService.getPage page
            .then (posts) ->
                $log.debug 'Got posts', posts
                $scope.posts = Array.prototype.concat $rootScope.posts, posts
                $rootScope.state = 'ready'
            .catch (err) ->
                $scope.error = err
                $rootScope.state = 'error'
        $log.debug 'Post Controller ready'
        $scope.load $routeParams.page || 1
]