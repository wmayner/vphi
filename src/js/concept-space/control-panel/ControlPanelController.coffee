'use strict'
###
# concept-space/control-panel/ControlPanelController.coffee
###

log = require 'loglevel'
computeService = require '../../services/compute'
networkService = require '../../services/network'

module.exports = [
  '$scope'
  computeService.name
  networkService.name
  ($scope, compute, network) ->
    $scope.resetCamera = -> $scope.canvas.resetCamera()

    $scope.format = compute.format

    $scope.restoreNetwork = -> network.loadJSON(compute.network)
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
