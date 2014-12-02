###
A layer on top of a directed graph that provides functions for getting the
state of elementary mechanisms and traversing them in order.
###
utils = require './utils'

getAllStates = (numNodes) ->
  return (utils.indexToState(i, numNodes) for i in [0...Math.pow(2, numNodes)])

checkPossiblePastState = (tpm, pastStateIndex, currentState) ->
  row = tpm[pastStateIndex]
  for i in [0...currentState.length]
    if ((currentState[i] > 0 and row[i] is 0) or
        (currentState[i] is 0 and row[i] isnt 0))
      return false
  return true

module.exports =

  # Return the given property for each node, in order of node labels.
  getNodeProperties: (graph, property, node_indices) ->
    if node_indices?
      return (node[property] for node in graph.getNodesByLabel() when node.label in node_indices)
    else
      return (node[property] for node in graph.getNodesByLabel())

  getCurrentState: (graph, node_indices) ->
    # We need to read the bits in reverse because of how repertoire arrays are
    # flattened.
    return @getNodeProperties(graph, 'on', node_indices)

  getPastState: (graph, node_indices) ->
    if not graph.pastState
      return false
    return (graph.pastState[i] for i in node_indices)

  # TODO test
  getConnectivityMatrix: (graph) ->
    (((if graph.getEdge(sourceId, targetId) then 1 else 0) \
      for targetId in [0...graph.nodeSize]) for sourceId in [0...graph.nodeSize])

  getPossiblePastStates: (tpm, currentState) ->
    numNodes = currentState.length
    numStates = tpm.length
    result = (utils.indexToState(pastStateIndex, numNodes) \
      for pastStateIndex in [0...numStates] \
      when checkPossiblePastState(tpm, pastStateIndex, currentState))
    if result.length is 0
      return false
    return result
