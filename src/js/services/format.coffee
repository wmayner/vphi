'use strict'
###
# services/format.coffee
###

graph = require './graph'

PRECISION = 6

name = 'vphi.services.format'
module.exports = angular.module name, []
  .factory name, [
    graph.name
    (graph) ->
      return new class FormatService
        node: (index) -> graph.getNodeByIndex(index).label

        nodes: (node_indices) -> (@node(i) for i in node_indices)

        phi: (phiValue) -> d3.round(phiValue, PRECISION)

        latexNodes: (nodeArray) -> @nodes(nodeArray).join('') or '[\\,]'
  ]

