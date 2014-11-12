###
API for PyPhi's RPC server.
###

network = require './network'
tpmify = require './tpmify'

# TODO change endpoint
pyphi = new $.JsonRpcClient({
  ajaxUrl: 'http://localhost:4000/'
})

NETWORK_SIZE_LIMIT = 5

module.exports =

  bigMip: (graph, success, subsystem_indices) ->
    tpm = tpmify(graph)
    if not subsystem_indices?
      subsystem_indices = [0...graph.nodeSize]
    currentState = network.getCurrentState(graph, subsystem_indices)
    cm = network.getConnectivityMatrix(graph)
    if currentState.length > NETWORK_SIZE_LIMIT
      throw Error("Network cannot have more than #{NETWORK_SIZE_LIMIT} nodes.")
    # TODO Allow for subsystems, where past state matters
    pyphiNetwork =
      'tpm': tpm
      'currentState': currentState
      'connectivityMatrix': cm
    params = [
      subsystem_indices
      pyphiNetwork
    ]
    result = null
    # Failure callback.
    failure = (error) ->
      console.error error
    # Make the remote call.
    return pyphi.call 'big_mip', params, success, failure
