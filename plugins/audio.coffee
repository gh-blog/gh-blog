_       = require 'lodash'
cheerio = require 'cheerio'

module.exports = (options) ->
    audio = 'a'
    FILTERS = [
        (href) ->
            matches = href.match /soundcloud.com/gi
            if matches
                id = matches[1]
                "
                <iframe
                    width='100%' height='450' scrolling='no' frameborder='no'
                    src='https://w.soundcloud.com/player/?url=
                    https%3A//api.soundcloud.com/tracks/#{id}&amp;auto_play=false&amp;hide_related=false&amp;show_comments=true&amp;show_user=true&amp;show_reposts=false&amp;visual=true'>
                </iframe>
                "
            else null
    ]

    options = _.defaults options,
        soundcloud: yes
        local: yes

    (post) ->
        $ = cheerio.load post.html
        $('a').each ->
            href = $(this).attr('href')
            for filter in filters when not $.data 'matched'
                filter.process href

        post.html = $.html()
        @emit 'end', post