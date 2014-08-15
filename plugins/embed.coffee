through2 = require 'through2'
marked = require 'marked'
async = require 'async'
request = require 'request'
_ = require 'lodash'
secret = require '../secret.json'

module.exports = (options) ->
    processFile = (file, enc, done) ->
        { $ } = file
        file.videos = 0
        file.images = 0

        isExternal = (i, el) ->
            $el = $ el
            url = $el.attr('href') || $el.attr('src')

            if url and url.match /^http/i
                $el.data 'url', url
                return yes
            no

        # @TODO check options...
        isEmbeddable = (i, el) ->
            url = $(el).data 'url'
            url and url.match /youtube.com/ig

        getOEmbed = (urls..., done) ->
            return done null, [] if not urls.length
            # @TODO: iframely
            # req =
            #     url: "http://iframe.ly/api/oembed\
            #     ?api_key=#{secret.iframely.api_key}\
            #     &url=#{url}"
            req =
                url: "http://api.embed.ly/1/oembed\
                ?key=#{secret.embedly.api_key}\
                &urls=#{ urls.join ',' }\
                &format=json"

            # @TODO DEBUG req.url

            request.get req, (err, res) ->
                if err
                    # @TODO: log WARN
                    return done err, []
                try
                    jsonArray = JSON.parse res.body
                    done null, jsonArray
                catch e
                    # @TODO: log DEBUG
                    done e, []

        getEmbed = (externals, done) ->
            $externals = $ externals

            $urlElements = []
            urls = []

            $externals.each (i, el) ->
                $el = $ el
                url = $el.data 'url'
                $urlElements.push $el
                urls.push url

            getOEmbed urls, (err, jsonArray) ->
                console.log 'JSON', jsonArray
                for jsonObj, i in jsonArray
                    try $urlElements[i].html jsonObj.html
                    switch jsonObj.type
                        when 'video'
                            file.videos += 1
                        when 'image'
                            file.images += 1
                done()

        externals = $('*')
            .filter(isExternal)
            .filter(isEmbeddable).toArray()

        async.each externals, getEmbed, (err) ->
            file.contents = new Buffer $.html()
            done null, file

    through2.obj processFile