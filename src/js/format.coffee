###
# format.coffee
###

PRECISION = 6

class PhiFormatter
  constructor: ->

  node: (index) -> vphiGraphService.graph.getNodeByIndex(index).label

  nodes: (node_indices) -> (@node(i) for i in node_indices)

  phi: (phiValue) -> d3.round(phiValue, PRECISION)

  latexNodes: (nodeArray) -> @nodes(nodeArray).join('') or '[\\,]'


module.exports = new PhiFormatter()
