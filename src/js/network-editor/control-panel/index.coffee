'use strict'
###
# network-editor/control-panel/index.coffee
###

module.exports = angular.module 'vphi.networkEditor.controlPanel', [
  # SVG Downloader
  'hc.downloader'
]
  .controller 'networkEditor.controlPanelCtrl', require './ControlPanelController'
