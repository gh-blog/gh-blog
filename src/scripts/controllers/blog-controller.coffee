module.exports = [
    '$rootScope', '$scope', '$q', 'ContentService', '$routeParams', '$log'
    ($rootScope, $scope, $q, ContentService, $routeParams, $log) ->
        $scope.pages = []
        $rootScope.state = 'loading'
        $scope.canLoad = -> $scope.pages.length < $rootScope.blog.pages
        $scope.load = (page = $scope.pages.length + 1) ->
            $log.debug "Loading page #{page}..."
            $rootScope.state = 'loading'
            ContentService.getPage page
            .then (posts) ->
                $log.debug 'Got posts', posts
                $scope.pages[page - 1] = posts
                $rootScope.state = 'ready'
            .catch (err) ->
                $rootScope.error = err
                $log.error 'Error', err
                $rootScope.state = 'error'
        $log.debug 'Post Controller ready'
        $scope.load $routeParams.page || 1
]