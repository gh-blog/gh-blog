_       = require 'lodash'

module.exports = (options) ->
    options = _.defaults options,
        local: yes
        youtube: yes
        vimeo: yes
        flickr: yes
        gplus: yes
        facebook: yes

    (post) ->
        # Do something!