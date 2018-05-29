'use strict'
###
# concept-space/control-panel/ControlPanelDirective.coffee
###

module.exports = ->
  return {
    scope: true
    controller: 'conceptSpace.ControlPanelCtrl'
    bindToController: {
    }
    templateUrl: 'ConceptSpaceControlPanel.html'
  }
