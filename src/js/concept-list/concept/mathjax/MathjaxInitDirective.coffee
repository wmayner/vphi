'use strict'
###
# concept-list/concept/mathjax/MathjaxInitDirective.coffee
###

module.exports = ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    script = angular.element("<script type='math/tex'>")
      .html(attrs.mathjaxInit)
    element.append(script)
    MathJax.Hub.Queue ['Typeset', MathJax.Hub, element[0]]
