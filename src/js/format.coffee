###
# format.coffee
###

graph = require('./graph-editor').graph


PRECISION = 6


class Formatter
  constructor: ->

  node: (index) -> graph.getNodeByIndex(index).label

  # TODO Provide graph in an angular service.
  nodes: (node_indices) -> (@node(i) for i in node_indices)

  phi: (phiValue) -> d3.round(phiValue, PRECISION)

  latexNodes: (nodeArray) -> @nodes(nodeArray).join('') or '[\\,]'


module.exports = new Formatter()
