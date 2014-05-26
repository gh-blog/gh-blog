angular = require 'angular'
require 'angular-route'
app = angular.module 'blog', ['ngRoute']

app.service 'CacheService', require './services/cache-service'
app.service 'ContentService', require './services/content-service'
app.controller 'BlogController', require './controllers/blog-controller'
app.controller 'PostController', require './controllers/post-controller'
app.directive 'markdown', require './directives/markdown-directive'
app.directive 'disqus', require './directives/disqus-directive'

app.config [
    '$routeProvider', '$locationProvider', '$logProvider',
    ($routeProvider, $locationProvider, $logProvider) ->
        $logProvider.debugEnabled yes
        $routeProvider
        .when '/posts/:id',
            controller: 'PostController'
            templateUrl: 'views/post.html'
            resolve: [
                '$route', 'ContentService',
                ($route, ContentService) ->
                    ContentService.getPost $route.current.params.id
                    .then (post) -> angular.extend $route.current.params, post
            ]
        .when '/',
            controller: 'BlogController'
            templateUrl:    'views/blog.html'
        .otherwise redirectTo: '/'

        $locationProvider.hashPrefix '!'
]

app.run ['$log', ($log) ->
    $log.debug 'Ready'
]
