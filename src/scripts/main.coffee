angular = require 'angular'
require 'angular-route'
require 'angular-sanitize'

app = angular.module 'blog', ['ngRoute', 'ngSanitize']

app.service 'CacheService', require './services/cache-service'
app.service 'ContentService', require './services/content-service'
app.controller 'HomeController', require './controllers/home-controller'
app.controller 'PostController', require './controllers/post-controller'
app.directive 'disqus', require './directives/disqus-directive'
app.directive 'infiniteScroll', require './directives/infinite-scroll-directive'
app.directive 'timeAgo', require './directives/time-ago-directive'
app.filter 'moment', require './filters/moment-filter'

app.config [
    '$routeProvider', '$locationProvider', '$logProvider',
    ($routeProvider, $locationProvider, $logProvider) ->
        $logProvider.debugEnabled yes
        $routeProvider
        .when '/:id',
            controller: 'PostController'
            templateUrl: 'views/post.html'
        .otherwise
            controller: 'HomeController'
            templateUrl: 'views/home.html'

        $locationProvider.hashPrefix '!'
]

app.run ['$rootScope', '$log', ($rootScope, $log) ->
    $log.debug 'Ready'
    $rootScope.state = 'loading'
]
