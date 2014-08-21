gulp            = require 'gulp'
gutil           = require 'gulp-util'
merge           = require 'merge-stream'
_               = require 'lodash'
changeCase      = require 'change-case'
Q               = require 'q'

fs              = require 'fs'
exec            = require('child_process').exec
mkdirp          = require 'mkdirp'
path            = require 'path'
async           = require 'async'
glob            = require 'glob'

connect         = require 'connect'
pause           = require 'connect-pause'

Feed            = require 'feed'
moment          = require 'moment'

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
    postsPerPage: 10
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

gulp.task 'locale', ['config'], ->
    config.blog.post = {
        type: 'text'
        dateFormatted: 'منذ ساعتين'
    }

    localize 'en', _.omit config.blog, 'locale'
    .on 'localeData', (data) ->
        config.blog.locale = data
        console.log data

gulp.task 'jade', ['config', 'locale', 'markdown', 'scripts', 'styles'], ->
    locals = _.extend config.blog, {
        styles: [
            '/styles/main.css'
        ]
        scripts: ['/scripts/main.js']
        icons: []
    }

    index =
        gulp.src config.src.jade, cwd: 'src', base: 'src'
        .pipe plugins.cached 'jade'
        .pipe plugins.using()
        .pipe plugins.jade
            pretty: config.env isnt 'production'
            locals: locals
        .pipe gulp.dest "#{config.dest}"
        .on 'error', (err) -> throw err

    streams = [index]

    getStream = (post) ->
        postLocals = _.clone config.blog, yes
        postLocals.post = post

        gulp.src config.src.jadePost, cwd: 'src', base: 'src'
        .pipe plugins.jade
            pretty: config.env isnt 'production'
            locals: postLocals
        .pipe plugins.rename (file) ->
            file.basename = post.id
            console.log(file)
            file
        .pipe gulp.dest "#{config.dest}/content"
        .on 'error', (err) -> throw err

    for post in _.flatten config.blog.pages
        console.log 'Adding post', post.id
        streams.push getStream post

    merge streams
    .on 'error', (err) -> throw err

gulp.task 'lint', ->
    # if config.lint
    #     gulp.src config.src.coffee, cwd: 'src'
    #     .pipe (plugins.coffeelint())
    #     .pipe (plugins.coffeelint.reporter())


gulp.task 'coffee', ['lint'], ->
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

gulp.task 'avatar', ['config'], ->
    gulp.src config.blog.image, cwd: 'src'
    .pipe gulp.dest config.dest

gulp.task 'images', ['avatar'], ->
    gulp.src config.src.images, cwd: 'posts/images'
    .pipe plugins.cached 'images'
    .pipe plugins.using()
    .pipe gulp.dest "#{config.dest}/content/images"

# @deprecated
gulp.task 'markdown', ['config'], (done) ->
    posts = []
    gulp.src config.src.markdown, cwd: 'posts'
    .pipe plugins.cached 'markdown'
    .pipe(
        Post(config.blog)
        .on 'post', (post) ->
            posts.push post
        .on 'end', ->
            posts = _.sortBy posts, 'date'
            files = []
            totalPages = Math.round posts.length/config.postsPerPage

            for post, i in posts by config.postsPerPage
                files.push posts[i...i + config.postsPerPage].reverse().map (post) ->
                    post.page = files.length + 1
                    post

            config.posts = _.flatten(posts).reverse()
            config.blog.postsPerPage = config.postsPerPage

            gutil.log gutil.colors.green "Finished processing #{posts.length} posts in #{files.length} pages"
            j = 0
            config.blog.pages = files

    ).pipe gulp.dest "#{config.dest}/content"


gulp.task 'posts', ['config', 'styles', 'scripts'], ->

    # @TODO: fix styles, icons and scripts
    config.blog.styles = ['/styles/main.css']
    config.blog.scripts = ['/scripts/main.js']

    # @TODO .pipe paginate()
    # @TODO .pipe images()
    secret = require './secret.json'
    html = require './plugins/pipelog-marked'
    highlight = require './plugins/pipelog-highlightjs'
    autodir = require './plugins/pipelog-auto-dir'
    embed = require './plugins/pipelog-embedly'
    generate = require './plugins/pipelog-static'
    info = require './plugins/pipelog-info'
    type = require './plugins/pipelog-post-type'
    metadata = require './plugins/pipelog-git-metadata'
    git = require './plugins/pipelog-git-status'
    images = require './plugins/pipelog-images'
    localize = require './plugins/pipelog-l20n'

    gulp.src config.src.markdown, cwd: './posts'
    .pipe plugins.cached 'markdown'
    # .pipe git.status repo: './posts' # @TODO: fix dir bug
    # .pipe plugins.ignore.exclude (file) ->
    #     # Ignore unmodified files to make things faster
    #     file.status is 'unmodified' or
    #     file.status is 'untracked'
    .pipe metadata './posts'
    .pipe html()
    .pipe info blog: config.blog
    .pipe plugins.tap (file) ->
        # Everything that has been changed or added
        gutil.log "Adding #{file.status} post #{file.title}"
        gutil.log "File added on #{file.dateAdded}"
        try gutil.log "File modified on #{file.dateModified}"
    .pipe highlight()
    .pipe autodir fallback: config.blog.dir || 'ltr'
    .pipe images dir: 'images' # @TODO: figure out how to add a file to stream
    .pipe embed secret.embedly
    .pipe type()
    .pipe localize 'ar', config.blog
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
            json.link = "http://localhost:#{config.port}"
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