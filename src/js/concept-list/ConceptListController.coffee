'use strict'
###
# concept-list/ConceptListCtrl.coffee
###

computeService = require '../services/compute'

module.exports = [
  '$scope'
  computeService.name
  ($scope, compute) ->
    $scope.concepts = null
    $scope.numNodes = null
    $scope.currentState = null

    $scope.$on (computeService.name + '.updated'), ->
      $scope.concepts = compute.data.unpartitioned_constellation
      $scope.numNodes = compute.data.subsystem.node_indices.length
      $scope.currentState = compute.data.currentState

      # Merge all unpartitioned and partitioned repertoires and find the max.
      allRepertoires = (
        c.cause.repertoire
          .concat(c.cause.partitioned_repertoire)
          .concat(c.effect.repertoire)
          .concat(c.effect.partitioned_repertoire) for c in $scope.concepts
      )
      allProbabilities = [].concat.apply([], allRepertoires)
      $scope.maxProbability = _.max(allProbabilities)

      log.debug "CONCEPT_LIST: Updated concept list."
]