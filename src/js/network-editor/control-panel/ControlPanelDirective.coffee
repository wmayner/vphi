'use strict'
###
# network-editor/control-panel/ControlPanelDirective.coffee
###

module.exports = ->
  return {
    scope: true
    controller: 'networkEditor.ControlPanelCtrl'
    controllerAs: '$ctrl'
    bindToController: {
      onUpdateLabel: '&'
      activeNode: '='
      selectedNodes: '<'
    }
    templateUrl: 'NetworkEditorControlPanel.html'
  }
