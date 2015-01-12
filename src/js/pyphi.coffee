###
# pyphi.coffee
#
# API for PyPhi's RPC server.
###

error = require './errors'


# TODO*** change endpoint
pyphi = new $.JsonRpcClient({
  ajaxUrl: 'http://127.0.0.1:5000/'
})


NETWORK_SIZE_LIMIT = 8


validate = (graph) ->
  # Get the current state and connectivity matrix.
  if not graph.pastState
    # TODO display error
    throw error.stateUnreachable()
  # Check for too-large networks
  if graph.nodeSize > NETWORK_SIZE_LIMIT
    throw error.networkSizeLimit(NETWORK_SIZE_LIMIT)

getPyphiNetwork = (graph) ->
  'tpm': graph.tpm
  'currentState': graph.currentState
  'connectivityMatrix': graph.getConnectivityMatrix()
  'pastState': graph.pastState

# Failure callback.
failure = (error) ->
  console.error error


module.exports =

  complexes: (graph, success) ->
    validate(graph)

    params = [getPyphiNetwork(graph)]

    return pyphi.call 'complexes', params, success, failure

  bigMip: (graph, success, subsystemIndices) ->
    # Use whole system by default.
    if not subsystemIndices?
      subsystemIndices = [0...graph.nodeSize]

    validate(graph)

    params = [
      subsystemIndices
      getPyphiNetwork(graph)
    ]

    return pyphi.call 'big_mip', params, success, failure
