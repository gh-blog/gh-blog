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

Feed            = require 'feed'
Post            = require './post'

plugins = (require 'gulp-load-plugins')()

config = _.defaults gutil.env,
    port: 7000 # on which port the server will be listening
    env: if gutil.env.production then 'production' else 'development'
    styles: []
    scripts: []
    icons: []
    blog: { }
    postsPerPage: 10
    cacheManifest: 'manifest.cache' # name of HTML5's ApplicationCache manifest file
    src:
        icons: 'icons/*.png'
        manifest: 'manifest.coffee'
        less: 'styles/main.less'
        fonts: 'styles/fonts/*'
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

minifyJSON = ->
    plugins.tap (file) ->
        json = JSON.parse file.contents.toString()
        file.contents = new Buffer JSON.stringify json
        file

gulp.task 'watch', ->
    # server = livereload();
    gulp.watch config.src.manifest, cwd: 'src', ['manifest']
    gulp.watch [config.watch.coffee, config.src.js], cwd: 'src', ['scripts', 'styles', 'html']
    gulp.watch config.watch.jade, cwd: 'src', ['styles', 'html']
    gulp.watch [config.watch.less, config.src.fonts], cwd: 'src', ['styles']
    gulp.watch config.images, cwd: 'images', ['images']
    gulp.watch config.src.markdown, cwd: 'posts', ['content']

gulp.task 'clean', ->
    gulp.src ['**/*', '!.gitignore'], cwd: config.dest
    .pipe plugins.clean()

gulp.task 'less', ->
    gulp.src config.src.less, cwd: 'src'
    .pipe plugins.less paths: ['.', '../../node_modules']
    # .pipe (if config.env is 'production' then plugins.minifyCss(noAdvanced: yes) else gutil.noop())
    .pipe plugins.autoprefixer cascade: true
    .pipe gulp.dest "#{config.dest}/styles"

gulp.task 'fonts', ->
    gulp.src config.src.fonts, cwd: 'src'
    .pipe gulp.dest "#{config.dest}/styles/fonts"

gulp.task 'jade', ['scripts', 'styles'], ->
    gulp.src config.src.jade, cwd: 'src', base: 'src'
    .pipe plugins.jade
        pretty: if config.env is 'production' then no else yes
        locals:
            _.extend config.blog, {
                styles: [
                    'styles/main.css'
                ]
                scripts: ['scripts/main.js']
                icons: []
            }
    .pipe gulp.dest "#{config.dest}"

gulp.task 'coffee', ->
    gulp.src config.src.coffee, cwd: 'src', read: no
    .pipe plugins.browserify
        transform: ['coffeeify']
        extensions: ['.coffee']
    .pipe plugins.rename (file) ->
        file.extname = '.js'
        file
    # .pipe (if config.env is 'production' then plugins.uglify() else gutil.noop())
    .pipe gulp.dest "#{config.dest}/scripts"

gulp.task 'scripts', ['coffee']
gulp.task 'styles', ['less', 'fonts']
gulp.task 'html', ['jade']

gulp.task 'avatar', ['config'], ->
    gulp.src config.blog.image, cwd: 'src'
    .pipe gulp.dest config.dest

gulp.task 'images', ['avatar'], ->
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
        gutil.log gutil.colors.cyan "Processed #{post.id}"
    .on 'end', ->
        posts = _.sortBy posts, 'date'
        posts.reverse()
        config.posts = posts
        files = []
        for post, i in posts by config.postsPerPage
            files.push posts[i...i + config.postsPerPage]
        gutil.log gutil.colors.green "Finished processing #{posts.length} posts"
        j = 0
        async.each files, (file, done) ->
            j++
            config.blog.pages = files.length
            fs.writeFile "#{config.dest}/content/posts.#{j}.json",
                JSON.stringify(file), done
        , done
    null # We do not want to return the stream

gulp.task 'rss', ['config', 'json'], (done) ->
    process = (post) ->
        post.description = post.excerpt
        post.link = "#{config.blog.link}/#/#{post.id}"
        post.author = config.blog.author
        post

    feed = new Feed(_.extend config.blog)
    feed.addItem process post for post in config.posts

    xml = feed.render 'atom-1.0'
    fs.writeFile "#{config.dest}/rss.xml", xml, done


gulp.task 'content', ['markdown', 'json', 'images', 'rss']

gulp.task 'config', ['json'], ->
    gulp.src config.src.config, cwd: 'src'
    .pipe plugins.cson()
    .pipe plugins.jsonEditor (json) ->
        json = _.extend json, config.blog || {}
        config.blog = json
        json
    .pipe (if config.env is 'production' then minifyJSON() else gutil.noop())
    .pipe gulp.dest config.dest

gulp.task 'default', ['content', 'html', 'config']

gulp.task 'publish', ->
    gulp.src ['*', '**/*'], cwd: config.dest
    .pipe plugins.git.checkout 'gh-pages', options: '-f'

gulp.task 'serve', ->
    server = connect.createServer()
    server.use '/', connect.static "#{__dirname}/#{config.dest}"
    server.use '/', connect.static "#{__dirname}/src" if config.env isnt 'production'
    server.listen config.port, ->
        gutil.log "Server listening on port #{config.port}"