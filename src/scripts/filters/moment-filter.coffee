moment = require 'moment'
require 'moment/locale/ar'
module.exports = [
    '$log', '$rootScope'
    ($log, $rootScope) ->
        (date) ->
            # $log.debug "Got date for moment filter #{date}"
            moment.locale $rootScope.blog.language
            moment(new Date date).fromNow()
]