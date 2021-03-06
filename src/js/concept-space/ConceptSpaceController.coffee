'use strict'
###
# concept-space/ConceptSpaceController.coffee
###

ConceptSpaceCanvas = require './canvas'

computeService = require '../services/compute'

module.exports = [
  '$scope'
  computeService.name
  ($scope, compute) ->
    # Create the view.
    $scope.canvas = new ConceptSpaceCanvas(compute)

    # Update display when new data is computed.
    # TODO handle complexes
    $scope.$on (computeService.name + '.updated'), ->
      $scope.canvas.display(compute.data.bigMip)
]
