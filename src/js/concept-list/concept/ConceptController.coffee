'use strict'
###
# concept-list/ConceptCtrl.coffee
###

format = require '../../services/format'

module.exports = [
  '$scope'
  format.name
  ($scope, format) ->
    concept = $scope.concept

    $scope.format = format

    $scope.mechanism = concept.mechanism
    $scope.smallPhi = format.phi concept.phi
    $scope.smallPhiPast = format.phi concept.phi
    $scope.smallPhiPast = format.phi concept.cause.mip.phi
    $scope.smallPhiFuture = format.phi concept.effect.mip.phi

    # TODO replace with directives and templates
    $scope.causeMip = "\\frac{" +
      format.latexNodes(concept.effect.mip.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.effect.mip.purview) + "^{p}" +
      "}"
    $scope.partitionedCauseMip = "\\frac{" +
      format.latexNodes(concept.cause.mip.partition[0].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.cause.mip.partition[0].purview) + "^{p}" +
      "} \\times \\frac{" +
      format.latexNodes(concept.cause.mip.partition[1].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.cause.mip.partition[1].purview) + "^{p}" +
      "}"
    $scope.effectMip = "\\frac{" +
      format.latexNodes(concept.effect.mip.mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.effect.mip.purview) + "^{f}" +
      "}"
    $scope.partitionedEffectMip = "\\frac{" +
      format.latexNodes(concept.effect.mip.partition[0].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.effect.mip.partition[0].purview) + "^{f}" +
      "} \\times \\frac{" +
      format.latexNodes(concept.effect.mip.partition[1].mechanism) + "^{c}" +
      "}{" +
      format.latexNodes(concept.effect.mip.partition[1].purview) + "^{f}" +
      "}"
]
