moment = require 'moment'
require 'moment/locale/ar'
module.exports = [
    '$log', '$rootScope'
    ($log, $rootScope) ->
        (date, format) ->
            # $log.debug "Got date for moment filter #{date}"
            moment.locale $rootScope.blog.language
            if not format
                moment(new Date date).fromNow()
            else
                $log.debug "Format is #{format}"
                moment(new Date date).format(format)
]