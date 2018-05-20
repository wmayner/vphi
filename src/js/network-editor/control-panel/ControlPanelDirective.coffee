'use strict'
###
# network-editor/control-panel/ControlPanelDirective.coffee
###

module.exports = ->
  return {
    scope: {}
    controller: 'networkEditor.ControlPanelCtrl'
    controllerAs: '$ctrl'
    bindToController: {
      onUpdateLabel: '&'
      activeNode: '='
      selectedNodes: '<'
    }
    templateUrl: 'NetworkEditorControlPanel.html'
  }
