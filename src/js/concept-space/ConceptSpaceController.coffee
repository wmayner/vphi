'use strict'
###
# concept-space/ConceptSpaceController.coffee
###

ConceptSpaceCanvas = require './canvas'

computeService = require '../services/compute'
formatService = require '../services/format'

module.exports = [
  '$scope'
  computeService.name
  formatService.name
  ($scope, compute, format) ->
    # Create the view.
    $scope.canvas = new ConceptSpaceCanvas(format)

    # Update display when new data is computed.
    $scope.$on (computeService.name + '.updated'), -> $scope.canvas.display(compute.data)
]
