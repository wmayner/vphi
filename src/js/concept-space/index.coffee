'use strict'
###
# concept-space/index.coffee
###

module.exports = angular.module 'vphi.conceptSpace', [
  'ngAnimate'
  require('./control-panel').name
]
  .controller 'conceptSpaceCtrl', require './ConceptSpaceController'
  .directive 'conceptSpace', require './ConceptSpaceDirective'
