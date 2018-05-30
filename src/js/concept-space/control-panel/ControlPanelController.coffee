'use strict'
###
# concept-space/control-panel/ControlPanelController.coffee
###

log = require 'loglevel'
computeService = require '../../services/compute'

module.exports = [
  '$scope'
  computeService.name
  ($scope, compute) ->
    $ctrl = this

    $ctrl.format = compute.format
    $ctrl.restoreNetwork = -> compute.restoreNetwork()
    $ctrl.resetCamera = -> $ctrl.canvas.resetCamera()
    $ctrl.toggleGrids = -> $ctrl.canvas.toggleGrids()
    $ctrl.toggleIgnoredAxes = -> $ctrl.canvas.toggleIgnoredAxes()

    $ctrl.concepts = []

    $scope.$on compute.updateEvent, ->
      log.debug "CONCEPT_SPACE: Received data update event."
      $ctrl.concepts = compute.data.bigMip.ces.concepts

    $ctrl.highlightConcept = (i) -> $ctrl.canvas.highlightConcept(i)

    return
]
