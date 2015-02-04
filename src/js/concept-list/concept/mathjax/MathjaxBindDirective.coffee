'use strict'
###
# concept-list/concept/mathjax/MathjaxBindDirective.coffee
###

module.exports = ->
  restrict: 'A'
  controller: [
    '$scope'
    '$element'
    '$attrs'
    ($scope, $element, $attrs) ->
      $scope.$watch $attrs.mathjaxBind, (texExpression) ->
        $script = angular.element("<script type='math/tex'>")
          .html(texExpression or "")
        $element.html("")
        $element.append($script)
        MathJax.Hub.Queue ['Typeset', MathJax.Hub, $element[0]]
  ]
