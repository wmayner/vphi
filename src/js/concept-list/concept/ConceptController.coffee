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

    $scope.mechanism = concept.mechanism
    $scope.smallPhi = format.phi concept.phi
    $scope.smallPhiPast = format.phi concept.phi
    $scope.smallPhiPast = format.phi concept.cause.phi
    $scope.smallPhiFuture = format.phi concept.effect.phi

    # TODO replace with directives and templates
    $scope.causeMip = "\\frac{" +
      format.latexNodes(concept.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.cause.purview) + "^{p}" +
      "}"
    $scope.partitionedCauseMip = "\\frac{" +
      format.latexNodes(concept.cause.partition[0].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.cause.partition[0].purview) + "^{p}" +
      "} \\times \\frac{" +
      format.latexNodes(concept.cause.partition[1].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.cause.partition[1].purview) + "^{p}" +
      "}"
    $scope.effectMip = "\\frac{" +
      format.latexNodes(concept.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.effect.purview) + "^{f}" +
      "}"
    $scope.partitionedEffectMip = "\\frac{" +
      format.latexNodes(concept.effect.partition[0].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.effect.partition[0].purview) + "^{f}" +
      "} \\times \\frac{" +
      format.latexNodes(concept.effect.partition[1].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.effect.partition[1].purview) + "^{f}" +
      "}"
]
