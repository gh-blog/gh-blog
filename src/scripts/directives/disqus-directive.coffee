# Code from michaelbromley/angularUtils
module.exports = [
    '$window', '$log',
    ($window, $log) ->
        restrict: 'AE'
        scope:
            disqus_shortname: '@shortname',
            disqus_identifier: '@identifier',
            disqus_title: '@title',
            disqus_url: '@url',
            disqus_category_id: '@categoryId',
            disqus_disable_mobile: '@disableMobile',
            readyToBind: '@'
            count: '@'
        tempalte: '
            <div id="disqus_thread">
            </div>
            <a href="http://disqus.com" class="dsq-brlink">
                comments powered by
                <span class="logo-disqus">Disqus</span>
            </a>'
        replace: yes
        link: ($scope, $element) ->
            # ensure that the disqus_identifier and disqus_url are both set, otherwise we will run in to identifier conflicts when using URLs with "#" in them
            # see http://help.disqus.com/customer/portal/articles/662547-why-are-the-same-comments-showing-up-on-multiple-pages-
            if typeof $scope.disqus_identifier is 'undefined' or typeof $scope.disqus_url is'undefined'
                throw 'Please ensure that the `disqus-identifier` and `disqus-url` attributes are both set.'

            $scope.$watch 'readyToBind', (isReady) ->
                # If the directive has been called without the 'ready-to-bind' attribute, we
                # set the default to "true" so that Disqus will be loaded straight away.
                if !angular.isDefined isReady then isReady = 'true'
                if $scope.$eval isReady
                    # Put the config variables into separate global vars so that the Disqus script can see them
                    $window.disqus_shortname = $scope.disqus_shortname
                    $window.disqus_identifier = $scope.disqus_identifier
                    $window.disqus_title = $scope.disqus_title
                    $window.disqus_url = $scope.disqus_url
                    $window.disqus_category_id = $scope.disqus_category_id
                    $window.disqus_disable_mobile = $scope.disqus_disable_mobile
                    $element.attr('id', 'disqus_thread')
                    # Get the remote Disqus script and insert it into the DOM, but only if it not already loaded (as that will cause warnings)
                    if not $window.DISQUS
                        dsq = document.createElement('script')
                        dsq.type = 'text/javascript'
                        dsq.async = true;
                        dsq.src = "//#{$scope.disqus_shortname}.disqus.com/embed.js"

                        $log.debug 'dsq', dsq

                        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
                    else
                        $window.DISQUS.reset reload: yes,
                            config: ->
                                this.page.identifier = $scope.disqus_identifier;
                                this.page.url = $scope.disqus_url;
                                this.page.title = $scope.disqus_title;
]