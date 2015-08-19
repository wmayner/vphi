'use strict'
###
# network-editor/index.coffee
###

module.exports = angular.module 'vphi.networkEditor', [
  require('./control-panel').name
]
  .controller 'networkEditorCtrl', require './NetworkEditorController'
  .directive 'networkEditor', require './NetworkEditorDirective'
