gulp            = require 'gulp'
gutil           = require 'gulp-util'
_               = require 'lodash'

mkdirp          = require 'mkdirp'

connect         = require 'connect'
pause           = require 'connect-pause'

en              = require('lingo').en

plugins = (require 'gulp-load-plugins')()


config = _.defaults gutil.env,
    port: 7000 # on which port the server will be listening
    env: if gutil.env.production then 'production' else 'development'

    connection: throttle: gutil.env.throttle || 0
    blog: { }
    src:
        icons: 'icons/*.png'
        markdown: ['*.md', '!*.draft.md']
        config: 'config.json'

if config.env isnt 'production'
    config = _.defaults config,
        lint: yes
        sourceMaps: yes

config.dest = "dist/#{config.env}"

gulp.task 'posts', ['config'], ->

    # @TODO: fix styles, icons and scripts
    config.blog.styles = ['/styles/main.css']
    config.blog.scripts = ['/scripts/main.js']
    config.blog.icons = []

    Resolver = require './lib/resolver'
    resolver = new Resolver('../plugins')
    tasks = resolver.get_tasks_ordered()
    # console.log 'Tasks:', tasks

    secret          = require './secret.json'
    _p_config = { # @TODO: build the config API
        "gh-blog-git-metadata": { repo: './posts', authors: config.blog.authors }
        "gh-blog-git-status": { repo: './posts' }
        "gh-blog-auto-dir": { fallback: config.blog.dir || 'ltr' }
        "gh-blog-post-images": { dir: 'images' }
        "gh-blog-embedly": { api_key: secret.embedly.api_key }
        "gh-blog-disqus": { shortname: 'forabi' }
        "gh-blog-rss": { filename: 'rss.xml', blog: config.blog, resolve: '/posts' }
        "gh-blog-l20n": { localeCode: config.blog.language, blog: config.blog }
        "gh-blog-static": { blog: config.blog }
    }

    stream = gulp.src config.src.markdown, cwd: './posts'

    # console.log "path is #{config.dest}/posts"

    for task in tasks when task isnt 'gh-blog-dynamic' #and task isnt 'gh-blog-embedly'
        console.log "running #{task}"
        stream = stream.pipe require(task)(_p_config[task])

    stream.pipe gulp.dest "#{config.dest}/posts"



    # html            = require 'gh-blog-marked'
    # $               = require 'gh-blog-cheerio'
    # highlight       = require 'gh-blog-highlightjs'
    # autodir         = require 'gh-blog-auto-dir'
    # embed           = require 'gh-blog-embedly'
    # generate        = require 'gh-blog-static'
    # info            = require 'gh-blog-post-info'
    # type            = require 'gh-blog-post-type'
    # metadata        = require 'gh-blog-git-metadata'
    # git             = require 'gh-blog-git-status'
    # images          = require 'gh-blog-post-images'
    # localize        = require 'gh-blog-l20n'
    # rss             = require 'gh-blog-rss'
    # frontmatter     = require 'gh-blog-frontmatter'
    # excerpt         = require 'gh-blog-excerpt'
    # # disqus          = require 'gh-blog-disqus'
    # theme           = require 'gh-blog-default-theme'
    # paginate        = require 'gh-blog-pagination' # @TODO
    # emoji           = require 'gh-blog-emojione' # @TODO

    # gulp.src config.src.markdown, cwd: './posts'

    # .pipe git.status repo: './posts', cwd: '.'
    # # .pipe plugins.ignore.exclude (file) ->
    # #     # Ignore unmodified files to make things faster
    # #     # file.status is 'unmodified' or
    # #     file.status is 'untracked'
    # .pipe info blog: config.blog
    # .pipe metadata { repo: './posts', authors: config.blog.authors }
    # .pipe frontmatter()
    # .pipe html()
    # .pipe $()
    # .pipe emoji()
    # .pipe excerpt()
    # .pipe plugins.tap (file) ->
    #     # Everything that has been changed or added
    #     if file.isPost
    #         gutil.log "Adding #{file.status} post: #{gutil.colors.cyan file.title}"
    #         gutil.log 'Post author:', file.author.name
    #         gutil.log "Post written on #{file.created.date}"
    #         try gutil.log "Post last modified on #{file.modified.date}"
    #         try gutil.log "Post categories:", file.categories
    # .pipe highlight()
    # .pipe autodir fallback: config.blog.dir || 'ltr'
    # .pipe images dir: 'images'
    # # .pipe embed secret.embedly
    # .pipe type()
    # .pipe plugins.tap (file) ->
    #     try gutil.log "Post #{file.title} is of type #{file.type}" if file.isPost
    # .pipe rss 'rss.xml', config.blog, resolve: '/posts'
    # # .pipe disqus shortname: 'forabi'
    # .pipe plugins.tap (file) ->
    #     try gutil.log 'Comments', file.comments
    # .pipe theme()
    # .pipe paginate()
    # .pipe localize config.blog.language, config.blog
    # .pipe generate config.blog
    # # .pipe plugins.cached 'generated'
    # .pipe gulp.dest "#{config.dest}/posts"

gulp.task 'config', ->
    gulp.src config.src.config, cwd: 'src'
    .pipe plugins.jsonEditor (json) ->
        if config.env isnt 'production'
            json.link = "http://localhost:#{config.port}/"
            json.rss = "http://localhost:#{config.port}/rss.xml"
        json = _.extend json, config.blog || {}
        config.blog = json
        json
    .pipe (if config.env is 'production' then minifyJSON() else gutil.noop())
    .pipe gulp.dest config.dest

gulp.task 'serve', ->
    server = connect()
    server.use '/', connect.static "#{__dirname}/src" if config.env isnt 'production'

    if config.connection.throttle
        server.use pause config.connection.throttle
        gutil.log gutil.colors.magenta "Server is configured to simulate slow connections (#{config.connection.throttle/1000}s delay)"

    server.use '/', connect.static "#{__dirname}/#{config.dest}"

    server.listen config.port, ->
        gutil.log "Server listening on port #{config.port}"