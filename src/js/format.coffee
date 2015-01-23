###
# format.coffee
###

graph = require('./graph-editor').graph


PRECISION = 6


class Formatter
  constructor: ->

  node: (index) -> graph.getNodeByIndex(index).label

  # TODO Provide graph in an angular service.
  nodes: (node_indices) -> (@node(i) for i in node_indices).join(', ')

  phi: (phiValue) -> d3.round(phiValue, PRECISION)

  cut: (cut) ->
    if cut.severed.length is 0
      return 'N/A'
    intact = @nodes(cut.intact) or '[]'
    severed = @nodes(cut.severed) or '[]'
    return "#{severed} ⇏ #{intact}"

  latexNodes: (nodeArray) -> @nodes(nodeArray) or '[\\,]'


module.exports = new Formatter()
