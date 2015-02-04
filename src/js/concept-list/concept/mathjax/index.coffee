'use strict'
###
# concept-list/mathjax/index.coffee
###
#
module.exports = angular.module 'vphi.conceptList.mathjax', []
  .directive 'mathjaxBind', require './MathjaxBindDirective'
  .directive 'mathjaxInit', require './MathjaxInitDirective'
