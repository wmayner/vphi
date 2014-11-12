###
A layer on top of a directed graph that provides functions for getting the
state of elementary mechanisms and traversing them in order.
###


module.exports =

  ###
  Return the given property for each node, in order of node labels.
  ###
  getNodeProperties: (graph, property, node_indices) ->
    if node_indices?
      return (node[property] for node in graph.getNodesByLabel() when node.label in node_indices)
    else
      return (node[property] for node in graph.getNodesByLabel())

  getCurrentState: (graph, node_indices) ->
    return @getNodeProperties(graph, 'on', node_indices)

  getPastState: (graph, node_indices) ->
    return @getNodeProperties(graph, 'pastState', node_indices)

  # TODO test
  getConnectivityMatrix: (graph) ->
    return (((if graph.getEdge(sourceId, targetId) then 1 else 0) for targetId in [0...graph.nodeSize]) for sourceId in [0...graph.nodeSize])
