gulp            = require 'gulp'
gutil           = require 'gulp-util'
_               = require 'lodash'

fs              = require 'fs'
exec            = require('child_process').exec
mkdirp          = require 'mkdirp'
path            = require 'path'
async           = require 'async'
glob            = require 'glob'

connect         = require 'connect'
pause           = require 'connect-pause'

Feed            = require 'feed'

en              = require('lingo').en

plugins = (require 'gulp-load-plugins')()


config = _.defaults gutil.env,
    port: 7000 # on which port the server will be listening
    env: if gutil.env.production then 'production' else 'development'
    import:
        platform: switch
            when gutil.env.blogger then 'blogger'
            when gutil.env.tumblr then 'tumblr'
            when gutil.env.wordpress then 'wordpress'
            else null
        file: gutil.env['import-file']
        dest: gutil.env['import-dest']
        images: gutil.env['import-images'] || yes

    connection: throttle: gutil.env.throttle || 0
    styles: []
    scripts: []
    icons: []
    html: { }
    blog: { }
    postsPerPage: 10 # @TODO: deprecated
    src:
        icons: 'icons/*.png'
        manifest: 'manifest.coffee'
        less: 'styles/main.less'
        fonts: 'styles/fonts/*'
        jade: ['index.jade']
        jadePost: 'post.jade'
        coffee: ['scripts/main.coffee']
        js: 'scripts/*.js'
        markdown: ['*.md', '!*.draft.md']
        images: '**/*.{png,jpg,webp,gif}'
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
    gulp.watch config.src.images, cwd: 'images', ['posts/images']
    gulp.watch config.src.markdown, cwd: 'posts', ['content']
    gulp.watch config.src.config, cwd: 'src', ['config']

gulp.task 'clean', ->
    # @TODO: replace rimraf with something that removes files, not dirs
    gulp.src ['**/*', '!.gitignore', '!.git'], cwd: config.dest, read: no
    .pipe plugins.rimraf force: yes

gulp.task 'less', ->
    gulp.src config.src.less, cwd: 'src'
    .pipe plugins.less paths: ['.', '../../node_modules']
    .pipe (if config.env is 'production' then plugins.minifyCss(noAdvanced: yes) else gutil.noop())
    .pipe plugins.autoprefixer cascade: true
    .pipe gulp.dest "#{config.dest}/styles"

gulp.task 'fonts', ->
    gulp.src config.src.fonts, cwd: 'src'
    .pipe plugins.cached 'fonts'
    .pipe gulp.dest "#{config.dest}/styles/fonts"

gulp.task 'coffee', ->
    gulp.src config.src.coffee, cwd: 'src', read: no
    .pipe plugins.browserify
        transform: ['coffeeify']
        extensions: ['.coffee']
    .pipe plugins.rename (file) ->
        file.extname = '.js'
        file
    .pipe (if config.env is 'production'
            plugins.uglify mangle: no
            ###
              Mangling object names for angular-browserify
              will cause everything to break for some weird reason
            ###
        else gutil.noop())
    .pipe gulp.dest "#{config.dest}/scripts"

gulp.task 'scripts', ['coffee']
gulp.task 'styles', ['less', 'fonts']
gulp.task 'html', ['jade']

# @TODO: deprecate
gulp.task 'avatar', ['config'], ->
    gulp.src config.blog.image, cwd: 'src'
    .pipe gulp.dest config.dest

# @TODO: deprecate
gulp.task 'images', ['avatar'], ->
    gulp.src config.src.images, cwd: 'posts/images'
    .pipe plugins.cached 'images'
    .pipe plugins.using()
    .pipe gulp.dest "#{config.dest}/content/images"

# @TODO: deprecate
# gulp.task 'markdown', ['config'], (done) ->
#     posts = []
#     gulp.src config.src.markdown, cwd: 'posts'
#     .pipe plugins.cached 'markdown'
#     .pipe(
#         Post(config.blog)
#         .on 'post', (post) ->
#             posts.push post
#         .on 'end', ->
#             posts = _.sortBy posts, 'date'
#             files = []
#             totalPages = Math.round posts.length/config.postsPerPage

#             for post, i in posts by config.postsPerPage
#                 files.push posts[i...i + config.postsPerPage].reverse().map (post) ->
#                     post.page = files.length + 1
#                     post

#             config.posts = _.flatten(posts).reverse()
#             config.blog.postsPerPage = config.postsPerPage

#             gutil.log gutil.colors.green "Finished processing #{posts.length} posts in #{files.length} pages"
#             j = 0
#             config.blog.pages = files

#    ).pipe gulp.dest "#{config.dest}/content"


gulp.task 'posts', ['config', 'styles', 'scripts'], ->

    # @TODO: fix styles, icons and scripts
    config.blog.styles = ['/styles/main.css']
    config.blog.scripts = ['/scripts/main.js']

    # @TODO .pipe paginate()
    secret = require './secret.json'
    html = require 'gh-blog-marked'
    highlight = require 'gh-blog-highlightjs'
    autodir = require 'gh-blog-auto-dir'
    embed = require 'gh-blog-embedly'
    generate = require 'gh-blog-static'
    info = require 'gh-blog-post-info'
    type = require 'gh-blog-post-type'
    metadata = require 'gh-blog-git-metadata'
    git = require 'gh-blog-git-status'
    images = require 'gh-blog-post-images'
    localize = require 'gh-blog-l20n'
    hashtags = require 'gh-blog-hashtags'
    rss = require 'gh-blog-rss'

    gulp.src config.src.markdown, cwd: './posts'
    .pipe plugins.cached 'markdown'
    .pipe git.status repo: './posts', cwd: '.' # @TODO: fix dir bug
    # .pipe plugins.ignore.exclude (file) ->
    #     # Ignore unmodified files to make things faster
    #     # file.status is 'unmodified' or
    #     file.status is 'untracked'
    .pipe metadata './posts', config.blog.authors
    .pipe html()
    .pipe info blog: config.blog
    .pipe hashtags()
    .pipe plugins.tap (file) ->
        # Everything that has been changed or added
        if file.isPost
            gutil.log "Adding #{file.status} post: #{gutil.colors.cyan file.title}"
            gutil.log 'Post author:', file.author.name
            gutil.log "Post written on #{file.created.date}"
            try gutil.log "Post last modified on #{file.modified.date}"
            try gutil.log "Post categories:", file.categories
    .pipe highlight()
    .pipe autodir fallback: config.blog.dir || 'ltr'
    .pipe images dir: 'images'
    .pipe embed secret.embedly
    .pipe type()
    .pipe localize config.blog.language, config.blog
    .pipe rss 'rss.xml', config.blog, resolve: '/posts'
    .pipe generate config.blog
    .pipe gulp.dest "#{config.dest}/posts"

gulp.task 'rss', ['config', 'markdown'], (done) ->
    process = (post) ->
        post.link = "#{config.blog.link}/#!/#{post.id}"
        post.author = config.blog.author
        post.description = post.html
        post

    feed = new Feed(_.extend config.blog)
    feed.addItem process post for post in config.posts

    xml = feed.render 'atom-1.0'
    fs.writeFile "#{config.dest}/rss.xml", xml, done


gulp.task 'content', ['markdown', 'images', 'rss']

gulp.task 'config', ->
    gulp.src config.src.config, cwd: 'src'
    .pipe plugins.cson()
    .pipe plugins.jsonEditor (json) ->
        if config.env isnt 'production'
            json.link = "http://localhost:#{config.port}/"
            json.rss = "http://localhost:#{config.port}/rss.xml"
        json = _.extend json, config.blog || {}
        config.blog = json
        json
    .pipe (if config.env is 'production' then minifyJSON() else gutil.noop())
    .pipe gulp.dest config.dest

gulp.task 'build', ['content', 'html', 'config']
gulp.task 'default', ['build']

gulp.task 'publish', ['build'], (done) ->
    # run the script `./publish.sh`
    if config.env isnt 'production'
        throw new Error 'You can only publish production builds. Use the --production flag with this task.'

    cmd = "./publish.sh '#{config.blog.github.username}' '#{config.dest}'"
    gutil.log gutil.colors.cyan "Executing command #{cmd}..."
    exec cmd, (err, stdout, stderr) ->
        gutil.log stdout
        gutil.log stderr
        done err

gulp.task 'import', ->
    if not config.import.file
        throw new Error 'No import file specified. Specify one using the --import-file flag.'

    if not config.import.platform
        throw new Error 'No import platform specified. Specify one like --blogger or --wordpress.'

    if config.import.platform isnt 'blogger'
        throw new Error 'Currently, the import task only supports Blogger.'

    Importer = require "./importers/#{config.import.platform}"
    dir = config.import.dest || 'posts'
    mkdirp.sync dir

    gulp.src config.import.file
    .pipe (new Importer images: config.import.images)
    .on 'post', (post) ->
        gutil.log "Processed Blogger post \"#{post.id}\"."
    .on 'image', (url) ->
        plugins.download url
        .pipe gulp.dest "#{dir}/images"
    .on 'end', (posts) ->
        gutil.log gutil.colors.magenta "#{posts.length} Blogger #{en.pluralize 'post', posts.length} imported."
        gutil.log gutil.colors.green "Imported posts were saved to #{path.resolve dir}."
    .pipe gulp.dest dir

gulp.task 'serve', ->
    server = connect()
    server.use '/', connect.static "#{__dirname}/src" if config.env isnt 'production'

    if config.connection.throttle
        server.use pause config.connection.throttle
        gutil.log gutil.colors.magenta "Server is configured to simulate slow connections (#{config.connection.throttle/1000}s delay)"

    server.use '/', connect.static "#{__dirname}/#{config.dest}"

    server.listen config.port, ->
        gutil.log "Server listening on port #{config.port}"