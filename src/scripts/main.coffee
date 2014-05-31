angular = require 'angular'
require 'angular-route'
require 'angular-sanitize'

app = angular.module 'blog', ['ngRoute', 'ngSanitize']

app.service 'CacheService', require './services/cache-service'
app.service 'ContentService', require './services/content-service'
app.controller 'BlogController', require './controllers/blog-controller'
app.controller 'PostController', require './controllers/post-controller'
# app.directive 'markdown', require './directives/markdown-directive'
app.directive 'disqus', require './directives/disqus-directive'
app.directive 'infiniteScroll', require './directives/infinite-scroll-directive'
# app.directive 'masonry', require './directives/masonry-directive'

app.config [
    '$routeProvider', '$locationProvider', '$logProvider',
    ($routeProvider, $locationProvider, $logProvider) ->
        $logProvider.debugEnabled yes
        $routeProvider
        .when '/:page/:id',
            controller: 'PostController'
            templateUrl: 'views/post.html'
            resolve: [
                '$route', 'ContentService', '$rootScope'
                ($route, ContentService, $rootScope) ->
                    $rootScope.state = 'loading'
                    ContentService.getPost $route.current.params.id,
                        $route.current.params.page
                    .then (post) -> angular.extend $route.current.params, post
            ]
        .when '/:page?/?',
            controller: 'BlogController'
            templateUrl:    'views/blog.html'
        .otherwise redirectTo: '/'

        $locationProvider.hashPrefix '!'
]

app.run ['$log', ($log) ->
    $log.debug 'Ready'
]
