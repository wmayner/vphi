'use strict'
###
# network-editor/control-panel/ControlPanelDirective.coffee
###

module.exports = ->
  return {
    scope: true
    controller: 'networkEditor.controlPanelCtrl'
    controllerAs: '$ctrl'
  }
