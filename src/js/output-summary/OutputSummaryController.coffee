'use strict'
###
# output-summary/index.coffee
###

computeService = require '../services/compute'

module.exports = [
  '$scope'
  computeService.name
  ($scope, compute) ->
    format = compute.format
    $scope.format = compute.format

    $scope.elapsedTime = null
    $scope.bigPhiTime = null
    $scope.smallPhiTime = null
    $scope.state = null
    $scope.title = 'Subsystem'
    $scope.nodes = []
    $scope.cut = null
    $scope.bigPhi = '–'
    $scope.numConcepts = '–'
    $scope.sumSmallPhi = '–'

    $scope.$on (computeService.name + '.updated'), ->
      log.debug 'OUTPUT_SUMMARY: Received compute update.'

      bm = compute.data.bigMip

      if compute.calledMethod is 'mainComplex'
        $scope.title = 'Main Complex:'
      else
        $scope.title = 'Subsystem:'

      $scope.elapsedTime = format.time compute.data.elapsedTime
      $scope.bigPhiTime = format.time bm.time
      $scope.smallPhiTime = format.time bm.small_phi_time
      $scope.state = bm.state
      $scope.nodes = bm.subsystem.nodes
      $scope.bigPhi = format.phi bm.phi
      $scope.numConcepts = bm.unpartitioned_constellation.length

      if bm.unpartitioned_constellation.length > 0
        sumSmallPhi = (c.phi for c in bm.unpartitioned_constellation).reduce((x, y) -> x + y)
        $scope.sumSmallPhi = format.phi sumSmallPhi
      else
        $scope.sumSmallPhi = 0

      cut = bm.cut_subsystem.cut
      $scope.trivialCut = (cut[0].length < 1) or ($scope.nodes.length < 2)
      $scope.cut = [
        format.nodes cut[0]
        format.nodes cut[1]
      ]
]
