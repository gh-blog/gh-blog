moment = require 'moment'
require 'moment/lang/ar'
module.exports = [
    '$log', '$rootScope'
    ($log, $rootScope) ->
        (date) ->
            # $log.debug "Got date for moment filter #{date}"
            moment.lang $rootScope.blog.language
            moment(new Date date).fromNow()
]