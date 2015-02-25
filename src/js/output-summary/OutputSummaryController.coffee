'use strict'
###
# output-summary/index.coffee
###

computeService = require '../services/compute'
formatService = require '../services/format'

module.exports = [
  '$scope'
  computeService.name
  formatService.name
  ($scope, compute, format) ->
    $scope.time = null
    $scope.smallPhiTime = null
    $scope.currentState = null
    $scope.title = 'Subsystem'
    $scope.nodes = []
    $scope.cut = null
    $scope.bigPhi = '–'
    $scope.numConcepts = '–'
    $scope.sumSmallPhi = '–'

    $scope.$on (computeService.name + '.updated'), ->
      log.debug 'OUTPUT_SUMMARY: Received compute update.'

      d = compute.data

      if compute.calledMethod is 'mainComplex'
        $scope.title = 'Main Complex'
      else
        $scope.title = 'Subsystem'

      $scope.time = format.time d.time
      $scope.smallPhiTime = format.time d.small_phi_time
      $scope.currentState = d.currentState
      $scope.nodes = (format.node(i) for i in d.subsystem.node_indices)
      $scope.bigPhi = format.phi d.phi
      $scope.numConcepts = d.unpartitioned_constellation.length

      if d.unpartitioned_constellation.length > 0
        $scope.sumSmallPhi = format.phi (c.phi for c in d.unpartitioned_constellation).reduce((x, y) -> x + y)
      else
        $scope.sumSmallPhi = 0

      $scope.cut =
        intact: format.nodes d.cut_subsystem.cut.intact
        severed: format.nodes d.cut_subsystem.cut.severed
]
