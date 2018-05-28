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
    $scope.resetCamera = -> $scope.canvas.resetCamera()

    $scope.format = compute.format

    $scope.restoreNetwork = -> compute.restoreNetwork()
    $scope.resetCamera = -> $scope.canvas.resetCamera()
    $scope.toggleGrids = -> $scope.canvas.toggleGrids()
    $scope.toggleIgnoredAxes = -> $scope.canvas.toggleIgnoredAxes()
    $scope.switchView = ->
      # TODO implement switchView

    $scope.concepts = []

    $scope.$on (computeService.name + '.updated'), ->
      log.debug "CONCEPT_SPACE: Received data update event."
      $scope.concepts = compute.data.bigMip.ces.concepts

    $scope.highlightConcept = (i) -> $scope.canvas.highlightConcept(i)
]
