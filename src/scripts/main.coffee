angular = require 'angular'
require 'angular-route'
app = angular.module 'blog', ['ngRoute']

app.service 'ContentService', require './services/content-service'
app.controller 'BlogController', require './controllers/blog-controller'
app.controller 'PostController', require './controllers/post-controller'
app.directive 'markdown', require './directives/markdown-directive'

app.config ['$routeProvider', '$logProvider', ($routeProvider, $logProvider) ->
    $logProvider.debugEnabled no
    $routeProvider
    .when '/posts/:slug',
        controller: 'PostController'
        templateUrl:    'views/post.html'
        # resolve: text: ['$routeParams', ($routeParams) ->
        #     ContentService.getPost $routeParams.slug
        # ]
    .when '/',
        controller: 'BlogController'
        templateUrl:    'views/blog.html'
    .otherwise redirectTo: '/'

]

app.run ['$log', ($log) ->
    $log.debug 'Ready'
]