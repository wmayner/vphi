###
Convert a network of mechanisms and edges into a Transition Probability
Matrix. This is a mapping from all possible network states to their following
states.

Unless otherwise noted, a `state` is a object mapping node IDs to a state (either 0 or 1).
###

utils = require '../utils'
mechanism = require './mechanism'

# Get the state of a node in the next timestep, given the current state of the graph.
getNewNodeState = (graph, index, state) ->
  # Grab the node.
  node = graph.getNodeByIndex(index)
  # Get the IDs of nodes that are inputs to this one.
  inputNodeIds = (edge.source._id for edge in graph.getInEdgesOf(node._id))
  # Get an array of their states.
  inputs = (state[inputNodeId] for inputNodeId in inputNodeIds)
  # Compute the new state of the node by plugging-in the inputs to its
  # mechanism.
  return mechanism.functions[node.mechanism](inputs)

# Get a map from nodes to their next states.
getNextNetworkState = (graph, state) ->
  return graph.mapByIndex (node) -> getNewNodeState(graph, node.index, state)

# TPMify!
module.exports = (graph) ->
  tpm = []
  for i in [0...Math.pow(2, graph.nodeSize)]
    state = utils.holiIndexToState(i, graph.nodeSize)
    tpm.push getNextNetworkState(graph, state)
  return tpm
