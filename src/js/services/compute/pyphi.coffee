###
# pyphi.coffee
#
# API for PyPhi's RPC server.
###

error = require './errors'


# TODO*** change endpoint
pyphi = new $.JsonRpcClient({
  # ajaxUrl: 'http://127.0.0.1:5000/'
  ajaxUrl: 'http://144.92.3.24'
  # 12 hr timeout
  timeout: 43200000
})


NETWORK_SIZE_LIMIT = 10


validate = (graph) ->
  # Get the current state and connectivity matrix.
  if not graph.pastState
    # TODO display error
    throw error.stateUnreachable()
  # Check for too-large networks
  if graph.nodeSize > NETWORK_SIZE_LIMIT
    throw error.networkSizeLimit(NETWORK_SIZE_LIMIT)

getPyphiNetwork = (graph) ->
  net =
    'tpm': graph.tpm
    'currentState': graph.currentState
    'connectivityMatrix': graph.getConnectivityMatrix()
    'pastState': graph.pastState
  log.debug "PYPHI: Sending network:"
  log.debug net
  return net

# Failure callback.
failure = (err) ->
  log.error err


module.exports =

  complexes: (graph, success) ->
    validate(graph)
    params = [getPyphiNetwork(graph)]
    return pyphi.call 'complexes', params, success, failure

  mainComplex: (graph, success) ->
    validate(graph)
    params = [getPyphiNetwork(graph)]
    return pyphi.call 'main_complex', params, success, failure

  bigMip: (graph, success) ->
    # Get the selected subsystem.
    subsystemIndices = graph.getSelectedSubsystem()

    validate(graph)

    params = [
      subsystemIndices
      getPyphiNetwork(graph)
    ]

    return pyphi.call 'big_mip', params, success, failure
