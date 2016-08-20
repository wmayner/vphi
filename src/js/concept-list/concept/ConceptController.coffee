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
    cause = concept.cause.mip
    effect = concept.effect.mip

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

    $scope.partitionedCauseMip = "\\frac{" +
      format.latexNodes(cause.partition.part0.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(cause.partition.part0.purview) + "^{p}" +
      "} \\times \\frac{" +
      format.latexNodes(cause.partition.part1.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(cause.partition.part1.purview) + "^{p}" +
      "}"

    $scope.effectMip = "\\frac{" +
      format.latexNodes(concept.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(effect.purview) + "^{f}" +
      "}"

    $scope.partitionedEffectMip = "\\frac{" +
      format.latexNodes(effect.partition.part0.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(effect.partition.part0.purview) + "^{f}" +
      "} \\times \\frac{" +
      format.latexNodes(effect.partition.part1.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(effect.partition.part1.purview) + "^{f}" +
      "}"
]
