'use strict'
###
# network-editor/control-panel/index.coffee
###

module.exports = angular.module 'vphi.networkEditor.controlPanel', [
  # SVG Downloader
  'hc.downloader'
  'angularFileUpload'
]
  .controller 'networkEditor.ControlPanelCtrl', require './ControlPanelController'
  .directive 'networkEditorControlPanel', require './ControlPanelDirective'
