module.exports = [
    '$rootScope', '$scope', '$q', 'ContentService', '$log'
    ($rootScope, $scope, $q, ContentService, $log) ->
        $rootScope.posts = []
        load = ->
            $rootScope.state = 'loading'
            ContentService.getPage 1
            .then (posts) ->
                $log.debug 'Got posts', posts
                $scope.posts = Array.prototype.concat $rootScope.posts, posts
                $rootScope.state = 'ready'
            .catch (err) ->
                $scope.error = err
                $rootScope.state = 'error'
        $log.debug 'Post Controller ready'
        load()
]