Things to do
=============
* [-] Remove Angular dependency, generate truly static files
* [ ] Limit JS to moment dates and some basic stuff with proper fallbacks
    * [ ] Implement search as a plugin
    * [ ] Rewrite moment.js dates as a plugin
    * [ ] Rewrite Disqus comments as a plugin, removing Angular dependency
* [-] Git-based checking for new and modified posts
* [ ] Plugin system
    * How to store configuration?
    * How to ensure plugin safety?
    * How to manage plugin dependencies?
    * How to order plugins?
    * How to attach to each building steps? (hooks?)
    * How to resolve versions?
    * Log plugin history with git logs (installs/removes)?
    * [ ] cli utility
    * [ ] markdown
    * [ ] emoji
    * [x] embed
        * [x] YouTube
        * [x] SoundCloud
        * [ ] GoodReads
        * [ ] ...
    * [ ] rss
    * [ ] search
    * [x] dynamic + relative date with moment.js
    * [ ] comments
        * [ ] Disqus
    * [ ] responsive images
    * [ ] importers
        * [ ] Blogger
        * [ ] WordPress
        * [ ] Tumblr: It does not support direct exporting of posts. However, there are some services that export Tumblr content to WordPress-compatible format. So providing a WordPress importer should do the job.
        * [ ] Markdown files
        * [ ] HTML files
        * [ ] ...
* [-] Localization