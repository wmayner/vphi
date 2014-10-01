###
Convert a network of mechanisms and edges into a Transition Probability
Matrix. This is a mapping from all possible network states to their following
states.

Unless otherwise noted, a `state` is a object mapping node IDs to a state (either 0 or 1).
###

# Convert a decimal index into an array of binary node states.
index2state = (i, numberOfNodes) ->
  return ((i >> n) & 1 for n in [0...numberOfNodes])

# Get the state of a node in the next timestep, given the current state of the graph.
getNewNodeState = (graph, id, state) ->
  # Grab the node.
  node = graph.getNode(id)
  # Get the IDs of nodes that are inputs to this one.
  inputNodeIds = (edge.source for edge in graph.getInEdgesOf(id))
  # Get an array of their states.
  inputs = (state[inputNodeId] for inputNodeId in inputNodeIds)
  # Compute the new state of the node by plugging-in the inputs to its
  # mechanism.
  return node.mechanism(inputs)

# Get a map from nodes to their next states.
getNextNetworkState = (graph, state) ->
  nextState = {}
  graph.forEachNode (node, id) ->
    nextState[id] = getNewNodeState(graph, id, state)
  return nextState

# TPMify!
module.exports = (graph) ->
  tpm = {}
  states = (index2state(i, graph.nodeSize) for i in (
      [0...Math.pow(2, graph.nodeSize)]))
  for state in states
    tpm[state] = getNextNetworkState(graph, state)
  return tpm
