'use strict'
###
# graph-editor/control-panel/index.coffee
###

module.exports = angular.module 'vphi.graphEditor.controlPanel', [
  # SVG Downloader
  'hc.downloader'
]
  .controller 'graphEditor.controlPanelCtrl', require './ControlPanelController'
