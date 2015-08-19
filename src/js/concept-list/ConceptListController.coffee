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
    $scope.state = null

    $scope.$on (computeService.name + '.updated'), ->
      log.debug "CONCEPT_LIST: Received data update event."

      bm = compute.data.bigMip

      $scope.concepts = bm.unpartitioned_constellation
      $scope.numNodes = bm.subsystem.node_indices.length
      $scope.state= bm.state

      # Merge all unpartitioned and partitioned repertoires and find the max.
      allRepertoires = (
        c.cause.repertoire
          .concat(c.cause.partitioned_repertoire)
          .concat(c.effect.repertoire)
          .concat(c.effect.partitioned_repertoire) for c in $scope.concepts
      )
      allProbabilities = [].concat.apply([], allRepertoires)
      $scope.maxProbability = _.max(allProbabilities)
]
