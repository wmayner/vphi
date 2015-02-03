'use strict'
###
# services/format.coffee
###

graph = require './graph'

PRECISION = 6

module.exports = angular.module 'vphi.services.format', []
  .factory 'vphi.services.format', [
    graph.name
    (graph) ->
      return new class FormatService
        node: (index) -> graph.getNodeByIndex(index).label

        nodes: (node_indices) -> (@node(i) for i in node_indices)

        phi: (phiValue) -> d3.round(phiValue, PRECISION)

        latexNodes: (nodeArray) -> @nodes(nodeArray).join('') or '[\\,]'
  ]

