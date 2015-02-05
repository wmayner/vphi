###
# pyphi.coffee
#
# API for PyPhi's RPC server.
###

# TODO*** change endpoint
pyphi = new $.JsonRpcClient({
  # ajaxUrl: 'http://127.0.0.1:5000/'
  ajaxUrl: 'http://144.92.3.24'
  # 12 hr timeout
  timeout: 43200000
})


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
    params = [getPyphiNetwork(graph)]
    return pyphi.call 'complexes', params, success, failure

  mainComplex: (graph, success) ->
    params = [getPyphiNetwork(graph)]
    return pyphi.call 'main_complex', params, success, failure

  bigMip: (graph, success) ->
    # Get the selected subsystem.
    subsystemIndices = graph.getSelectedSubsystem()

    params = [
      subsystemIndices
      getPyphiNetwork(graph)
    ]

    return pyphi.call 'big_mip', params, success, failure
