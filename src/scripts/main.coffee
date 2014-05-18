angular = require 'angular'
require 'angular-route'
app = angular.module 'blog', ['ngRoute']

app.service 'CacheService', require './services/cache-service'
app.service 'ContentService', require './services/content-service'
app.controller 'BlogController', require './controllers/blog-controller'
app.controller 'PostController', require './controllers/post-controller'
app.directive 'markdown', require './directives/markdown-directive'

app.config ['$routeProvider', '$logProvider', ($routeProvider, $logProvider) ->
    $logProvider.debugEnabled yes
    $routeProvider
    .when '/posts/:slug',
        controller: 'PostController'
        templateUrl: 'views/post.html'
        resolve: [
            '$route', 'ContentService',
            ($route, ContentService) ->
                ContentService.getPost $route.current.params.slug
                .then (post) -> angular.extend $route.current.params, post
        ]
    .when '/',
        controller: 'BlogController'
        templateUrl:    'views/blog.html'
    .otherwise redirectTo: '/'

]

app.run ['$log', ($log) ->
    $log.debug 'Ready'
]
