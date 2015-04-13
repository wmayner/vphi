'use strict'
###
# concept-space/control-panel/index.coffee
###

module.exports = angular.module 'vphi.conceptSpace.controlPanel', [
  # SVG Downloader
  'hc.downloader'
]
  .controller 'conceptSpace.controlPanelCtrl', require './ControlPanelController'
