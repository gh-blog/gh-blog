module.exports = [
    '$rootScope', '$scope', 'ContentService', '$routeParams', '$log'
    ($rootScope, $scope, ContentService, $routeParams, $log) ->

        $scope.pages = []
        $scope.single = yes if $routeParams.page

        pageNotFull = ->
            $scope.pages[0].length < $rootScope.blog.postsPerPage

        $scope.canLoad = ->
            not $scope.single and
            ($scope.pages.length < $rootScope.blog.pages or
            pageNotFull())

        $scope.load = (id = $rootScope.blog.pages - $scope.pages.length) ->
            ContentService.get { page: id }
            .then (page) ->
                $rootScope.state = 'ready'
                $log.debug "Page #{id} loaded."
                $scope.pages[$rootScope.blog.pages - id] = page

        $log.debug 'Home Controller ready'

        ContentService.get().then (config) ->
            $rootScope.blog = config
            $rootScope.title = config.title
            id = $routeParams.page || config.pages
            $scope.load id, config.pages
]