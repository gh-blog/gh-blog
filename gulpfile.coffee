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
cheerio         = require 'cheerio'
marked          = require 'marked'

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
    gulp.watch config.src.markdown, cwd: 'posts', ['*.md']

gulp.task 'clean', ->
    gulp.src ['**/*', '!.gitignore'], cwd: config.dest
    .pipe plugins.clean()

gulp.task 'less', ->
    gulp.src config.src.less, cwd: 'src'
    .pipe plugins.less paths: ['.', '../../node_modules']
    .pipe gulp.dest "#{config.dest}/styles"

gulp.task 'jade', ['scripts', 'styles'], ->
    gulp.src config.src.jade, cwd: 'src', base: 'src'
    .pipe plugins.jade
        locals:
            styles: [
                'styles/main.css'
                'http://code.ionicframework.com/ionicons/1.4.1/css/ionicons.min.css'
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

gulp.task 'markdown', ->
    gulp.src config.src.markdown, cwd: 'posts'
    .pipe gulp.dest "#{config.dest}/content"

gulp.task 'json', (done) ->
    posts = []
    regex = /(\d{4}\-\d{2}\-\d{2})\-(.+)\.md/i
    gulp.src config.src.markdown, cwd: 'posts'
    .pipe plugins.tap (file) ->
        markdown = fs.readFileSync(file.path).toString()
        html = marked markdown
        $ = cheerio.load html
        posts.push post =
            title: title = $('h1').text().trim() || null
            excerpt: $('p').first().text().trim() || null
            filename: filename = path.basename file.path
            slug: filename.match(regex)[2] || changeCase.paramCase title
            date: new Date(filename.match(regex)[1])
        posts = _.sortBy posts, 'date'
        posts.reverse()
        gutil.log gutil.colors.cyan "Processed #{post.slug}"
    .on 'end', ->
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

gulp.task 'content', ['markdown', 'json'], ->


gulp.task 'default', ['content', 'html']

gulp.task 'serve', ->
    server = connect.createServer()
    server.use '/', connect.static "#{__dirname}/#{config.dest}"
    server.use '/', connect.static "#{__dirname}/src" if config.env isnt 'production'
    server.listen config.port, ->
        gutil.log "Server listening on port #{config.port}"