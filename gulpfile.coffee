gulp            = require 'gulp'
gutil           = require 'gulp-util'
_               = require 'lodash'
changeCase      = require 'change-case'
Q               = require 'q'

fs              = require 'fs'
mkdirp          = require 'mkdirp'
path            = require 'path'
async           = require 'async'
glob            = require 'glob'

connect         = require 'connect'

Post            = require './post'

plugins = (require 'gulp-load-plugins')()

config = _.defaults gutil.env,
    port: 7000 # on which port the server will be listening
    env: if gutil.env.production then 'production' else 'development'
    styles: []
    scripts: []
    icons: []
    postsPerPage: 10
    cacheManifest: 'manifest.cache' # name of HTML5's ApplicationCache manifest file
    src:
        icons: 'icons/*.png'
        manifest: 'manifest.coffee'
        less: 'styles/main.less'
        css: 'styles/*.css'
        jade: ['index.jade', 'views/*.jade']
        coffee: ['scripts/main.coffee']
        js: 'scripts/*.js'
        markdown: '*.md'
        images: '**/*.{jpg,png,gif,webp}'
        config: 'config.coffee'
    watch:
        coffee: ['scripts/**/*.coffee']
        less: ['styles/**/*.{less,css}']
        jade: ['*.jade', '*/**/*.jade']

if config.env isnt 'production'
    config = _.defaults config,
        lint: yes
        sourceMaps: yes

config.dest = "dist/#{config.env}"

try
    mkdirp.sync "#{config.dest}/content"

gulp.task 'watch', ->
    # server = livereload();
    gulp.watch config.src.manifest, cwd: 'src', ['manifest']
    gulp.watch [config.watch.coffee, config.src.js], cwd: 'src', ['scripts', 'styles', 'html']
    gulp.watch config.watch.jade, cwd: 'src', ['styles', 'html']
    gulp.watch config.watch.less, cwd: 'src', ['styles']
    gulp.watch config.images, cwd: 'images', ['images']
    gulp.watch config.src.markdown, cwd: 'posts', ['markdown']

gulp.task 'clean', ->
    gulp.src ['**/*', '!.gitignore'], cwd: config.dest
    .pipe plugins.clean()

gulp.task 'less', ->
    gulp.src config.src.less, cwd: 'src'
    .pipe plugins.less paths: ['.', '../../node_modules']
    .pipe plugins.autoprefixer cascade: true
    .pipe gulp.dest "#{config.dest}/styles"

gulp.task 'jade', ['scripts', 'styles'], ->
    gulp.src config.src.jade, cwd: 'src', base: 'src'
    .pipe plugins.jade
        locals:
            styles: [
                'styles/main.css'
            ]
            scripts: ['scripts/main.js']
            icons: []
    .pipe gulp.dest "#{config.dest}"

gulp.task 'coffee', ->
    gulp.src config.src.coffee, cwd: 'src', read: no
    .pipe plugins.browserify
        transform: ['coffeeify']
        extensions: ['.coffee']
    .pipe plugins.rename (file) ->
        file.extname = '.js'
        file
    .pipe gulp.dest "#{config.dest}/scripts"

gulp.task 'scripts', ['coffee']
gulp.task 'styles', ['less']
gulp.task 'html', ['jade']

gulp.task 'images', ->
    gulp.src config.src.images, cwd: 'images'
    .pipe gulp.dest "#{config.dest}/content/images"

gulp.task 'markdown', ->
    gulp.src config.src.markdown, cwd: 'posts'
    .pipe gulp.dest "#{config.dest}/content"

gulp.task 'json', (done) ->
    posts = []
    gulp.src config.src.markdown, cwd: 'posts'
    .pipe plugins.tap (file) ->
        post = new Post(file)
        console.log "Post #{post.filename}", post
        posts.push post
        gutil.log gutil.colors.cyan "Processed #{post.slug}"
    .on 'end', ->
        posts = _.sortBy posts, 'date'
        posts.reverse()
        files = []
        for post, i in posts by config.postsPerPage
            files.push posts[i...i + config.postsPerPage]
        gutil.log gutil.colors.green "Finished processing #{posts.length} posts"
        j = 0
        async.each files, (file, done) ->
            j++
            fs.writeFile "#{config.dest}/content/posts.#{j}.json",
                JSON.stringify(file), done
        , done
    null # We do not want to return the stream

gulp.task 'content', ['markdown', 'json', 'images'], ->

gulp.task 'config', ->
    gulp.src config.src.config, cwd: 'src'
    .pipe plugins.cson()
    # .pipe plugins.jsonEditor (json) ->
    #     json
    .pipe gulp.dest config.dest

gulp.task 'default', ['content', 'html', 'config']

gulp.task 'serve', ->
    server = connect.createServer()
    server.use '/', connect.static "#{__dirname}/#{config.dest}"
    server.use '/', connect.static "#{__dirname}/src" if config.env isnt 'production'
    server.listen config.port, ->
        gutil.log "Server listening on port #{config.port}"
