###
API for PyPhi's RPC server.
###


# TODO*** change endpoint
pyphi = new $.JsonRpcClient({
  ajaxUrl: 'http://localhost:4000/'
})


NETWORK_SIZE_LIMIT = 5


module.exports =

  bigMip: (graph, success, subsystemIndices) ->
    # Use whole system by default.
    if not subsystemIndices?
      subsystemIndices = [0...graph.nodeSize]
    # Get the current state and connectivity matrix.
    if not graph.pastState
      # TODO display error
      throw Error("Current state cannot be reached by any past state.")
    # Check for too-large networks
    if graph.nodeSize > NETWORK_SIZE_LIMIT
      throw Error("Network cannot have more than #{NETWORK_SIZE_LIMIT} nodes.")

    pyphiNetwork =
      'tpm': graph.tpm
      'currentState': graph.currentState
      'connectivityMatrix': graph.getConnectivityMatrix()
      'pastState': graph.pastState
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
