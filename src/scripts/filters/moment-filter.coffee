moment = require 'moment'
# @TODO: get rid of this
require 'moment/locale/ar'
moment.locale 'ar'

module.exports = [
    '$log'
    ($log) ->
        (date, format) ->
            # $log.debug "Got date for moment filter #{date}"
            # moment.locale $scope.blog.locale.language
            if not format
                moment(new Date date).fromNow()
            else
                $log.debug "Format is #{format}"
                moment(new Date date).format(format)
]