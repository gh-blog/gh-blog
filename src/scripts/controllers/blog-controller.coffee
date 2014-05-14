module.exports = [
    '$rootScope', '$scope', 'ContentService', '$log'
    ($rootScope, $scope, ContentService, $log) ->
        load = ->
            $rootScope.state = 'loading'
            ContentService.get()
            .then (posts) ->
                $scope.posts = posts
                $log.debug 'Here', posts
                $rootScope.state = 'ready'
            , (err) ->
                $rootScope.error = err
                $log.debug err
                $rootScope.state = 'error'
        $log.debug 'Post Controller ready'
        load()
]