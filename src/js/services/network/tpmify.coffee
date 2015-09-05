###
# services/graph/tpmify.coffee
#
# Convert a network of mechanisms and edges into a Transition Probability
# Matrix. This is a mapping from all possible network states to their following
# states.
#
# Unless otherwise noted, a `state` is a object mapping node IDs to a state
# (either 0 or 1).
###

utils = require '../../utils'
mechanism = require './mechanism'

# TODO put this in network service?

# Get the state of a node in the next timestep, given the current state of the graph.
getNextNodeState = (network, state, node) ->
  # Get the IDs of nodes that are inputs to this one.
  inputNodes = (edge.source for edge in network.graph.getInEdgesOf(node._id))
  # Get an array of their states.
  inputs = (state[inputNode.index] for inputNode in inputNodes)
  # Compute the new state of the node by plugging-in the inputs to its
  # mechanism.
  if node.mechanism is '>' or node.mechanism is '<'
    return mechanism[node.mechanism](inputs, node.threshold)
  else
    return mechanism[node.mechanism](inputs)

# Get a map from nodes to their next states.
getNextNetworkState = (network, state) ->
  (getNextNodeState(network, state, node) for node in network.getNodes())

# TPMify!
module.exports = (network) ->
  tpm = []
  for i in [0...Math.pow(2, network.size())]
    state = utils.loliIndexToState(i, network.size())
    tpm.push getNextNetworkState(network, state)
  return tpm
