'use strict'
###
# concept-list/ConceptCtrl.coffee
###

computeService = require '../../services/compute'

module.exports = [
  '$scope'
  computeService.name
  ($scope, compute) ->
    format = compute.format
    $scope.format = compute.format

    concept = $scope.concept
    $scope.cause = cause = concept.cause.mip
    $scope.effect = effect = concept.effect.mip

    $scope.causePartition = cause.partition
    $scope.effectPartition = effect.partition

    $scope.mechanism = concept.mechanism
    $scope.smallPhi = format.phi concept.phi
    $scope.smallPhiPast = format.phi concept.phi
    $scope.smallPhiPast = format.phi cause.phi
    $scope.smallPhiFuture = format.phi effect.phi

    # TODO replace with directives and templates
    $scope.causeMip = "\\frac{" +
      format.latexNodes(concept.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(cause.purview) + "^{p}" +
      "}"

    $scope.effectMip = "\\frac{" +
      format.latexNodes(concept.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(effect.purview) + "^{f}" +
      "}"
]
