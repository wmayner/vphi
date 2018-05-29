'use strict'
###
# concept-space/control-panel/ControlPanelDirective.coffee
###

module.exports = ->
  return {
    scope: {}
    controller: 'conceptSpace.controlPanelCtrl'
    controllerAs: '$ctrl'
    bindToController: {
      canvas: '='
    }
    templateUrl: 'ConceptSpaceControlPanel.html'
  }
