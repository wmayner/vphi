'use strict'
###
# concept-list/concept/MathjaxBindDirective.coffee
###

module.exports = ->
  restrict: 'A'
  controller: [
    '$scope'
    '$element'
    '$attrs'
    ($scope, $element, $attrs) ->
      $scope.$watch $attrs.mathjaxBind, (value) ->
        $script = angular.element("<script type='math/tex'>")
          .html(value or "")
        $element.html("")
        $element.append($script)
        MathJax.Hub.Queue ['Reprocess', MathJax.Hub, $element[0]]
  ]
