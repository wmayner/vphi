'use strict'
###
# concept-space/control-panel/ControlPanelController.coffee
###

computeService = require '../../services/compute'

module.exports = [
  '$scope'
  computeService.name
  ($scope, compute) ->
    $scope.format = compute.format

    $scope.resetCamera = -> $scope.canvas.resetCamera()
    $scope.toggleGrids = -> $scope.canvas.toggleGrids()
    $scope.toggleIgnoredAxes = -> $scope.canvas.toggleIgnoredAxes()
    $scope.switchView = ->
      # TODO implement switchView

    $scope.concepts = []

    $scope.$on (computeService.name + '.updated'), ->
      log.debug "CONCEPT_SPACE: Received data update event."
      bm = compute.data.bigMip
      $scope.concepts = bm.unpartitioned_constellation

    $scope.highlightConcept = (i) -> $scope.canvas.highlightConcept(i)
]
