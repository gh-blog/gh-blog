_ = require 'lodash'

module.exports = [
    '$rootScope', '$scope', '$q', 'ContentService', '$routeParams', '$log'
    ($rootScope, $scope, $q, ContentService, $routeParams, $log) ->
        $scope.pages = []
        $rootScope.state = 'loading'

        pageNotFull = ->
            _.flatten($scope.pages).length < $rootScope.blog.postsPerPage

        $scope.canLoad = ->
            $scope.pages.length < $rootScope.blog.pages or
            pageNotFull()


        $scope.load = (page = $scope.last - 1) ->
            $log.debug "Loading page #{page}..."

            $rootScope.state = 'loading'

            ContentService.getPage page
            .then (posts) ->
                $rootScope.title = $rootScope.blog.title

                $log.debug 'Got posts', posts

                $scope.pages[$rootScope.blog.pages - page] = posts
                $scope.last = page

                $rootScope.state = 'ready'
            .catch (err) ->
                $rootScope.error = err
                $log.error 'Error', err
                $rootScope.state = 'error'

        $log.debug 'Post Controller ready'

        ContentService.getBlog().then ->
            $scope.load $routeParams.page || $rootScope.blog.pages
            .then ->
                $scope.load() if not $routeParams.page and pageNotFull()
]