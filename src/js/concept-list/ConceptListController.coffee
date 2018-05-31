'use strict'
###
# concept-list/ConceptListCtrl.coffee
###

log = require 'loglevel'
computeService = require '../services/compute'


typesetMath = ->
  # Typeset the concept list after it's loaded.
  MathJax.Hub.Queue ['Typeset', MathJax.Hub, 'concept-list-module']
  MathJax.Hub.Queue ->
    # Show it after typesetting.
    $('#concept-list-module').removeClass('hidden')
    # Need this to force the charts to recalculate their width after
    # the MathJax is rendered.
    $(window).trigger('resize')


module.exports = [
  '$scope'
  '$timeout'
  computeService.name
  ($scope, $timeout, compute) ->
    $scope.concepts = null
    $scope.numNodes = null
    $scope.state = null

    $scope.$on compute.updateEvent, ->
      log.debug "CONCEPT_LIST: Received data update event."

      bm = compute.data.bigMip

      $scope.concepts = bm.ces.concepts
      $scope.numNodes = bm.subsystem.nodes.length
      $scope.state = bm.state

      # Merge all unpartitioned and partitioned repertoires and find the max.
      allRepertoires = (
        c.cause.repertoire
          .concat(c.cause.partitioned_repertoire)
          .concat(c.effect.repertoire)
          .concat(c.effect.partitioned_repertoire) for c in $scope.concepts
      )
      allProbabilities = [].concat.apply([], allRepertoires)
      $scope.maxProbability = _.max(allProbabilities)

      # Wait until the concept list is loaded before typesetting math
      $timeout typesetMath, 0
]
