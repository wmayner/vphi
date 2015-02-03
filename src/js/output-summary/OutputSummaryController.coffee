'use strict'
###
# output-summary/index.coffee
###

compute = require '../services/compute'
format = require '../services/format'

module.exports = [
  '$scope'
  compute.name
  format.name
  ($scope, compute, format) ->
    $scope.format = format

    $scope.currentState = null
    $scope.title = 'Subsystem'
    $scope.nodes = []
    $scope.cut = null
    $scope.bigPhi = '–'
    $scope.numConcepts = '–'
    $scope.sumSmallPhi = '–'

    $scope.$on 'vphiDataUpdated', ->
      d = compute.data

      if compute.calledMethod is 'mainComplex'
        $scope.title = 'Main Complex'
      else
        $scope.title = 'Subsystem'


      $scope.currentState = d.currentState
      $scope.nodes = d.subsystem.node_indices
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
