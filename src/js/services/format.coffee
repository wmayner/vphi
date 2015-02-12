'use strict'
###
# services/format.coffee
###

network = require './network'

PRECISION = 6

name = 'vphi.services.format'
module.exports = angular.module name, []
  .factory name, [
    network.name
    (network) ->
      return new class FormatService
        node: (index) ->
          # Only return the first 8 characters of the label.
          network.getNode(index).label[..8]

        nodes: (node_indices) -> (@node(i) for i in node_indices)

        phi: (phiValue) -> d3.round(phiValue, PRECISION)

        latexNodes: (nodeArray) -> @nodes(nodeArray).join('') or '[\\,]'
  ]

