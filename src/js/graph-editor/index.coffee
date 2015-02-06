'use strict'
###
# graph-editor/index.coffee
###

module.exports = angular.module 'vphi.graphEditor', [
  require('./control-panel').name
]
  .controller 'graphEditorCtrl', require './GraphEditorController'
  .directive 'graphEditor', require './GraphEditorDirective'
