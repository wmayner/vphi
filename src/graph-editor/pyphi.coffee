###
API for PyPhi's RPC server.
###

network = require './network'
tpmify = require './tpmify'


# TODO*** change endpoint
pyphi = new $.JsonRpcClient({
  ajaxUrl: 'http://localhost:4000/'
})


NETWORK_SIZE_LIMIT = 5


module.exports =

  bigMip: (graph, success, subsystemIndices) ->
    tpm = tpmify(graph)
    # Use whole system by default.
    if not subsystemIndices?
      subsystemIndices = [0...graph.nodeSize]
    # Get the current state and connectivity matrix.
    currentState = network.getCurrentState(graph, subsystemIndices)
    pastState = network.getPastState(graph, subsystemIndices)
    if not pastState
      pastState = network.getPossiblePastStates(tpm, currentState)[0]
    if not pastState
      # TODO display error
      throw Error("Current state cannot be reached by any past state.")
    cm = network.getConnectivityMatrix(graph)
    # Check for too-large networks
    if currentState.length > NETWORK_SIZE_LIMIT
      throw Error("Network cannot have more than #{NETWORK_SIZE_LIMIT} nodes.")

    pyphiNetwork =
      'tpm': tpm
      'currentState': currentState
      'connectivityMatrix': cm
      'pastState': pastState
    params = [
      subsystemIndices
      pyphiNetwork
    ]
    result = null
    # Failure callback.
    failure = (error) ->
      console.error error

    # Make the remote call.
    return pyphi.call 'big_mip', params, success, failure
