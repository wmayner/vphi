###
# pyphi.coffee
#
# API for PyPhi's RPC server.
###

# TODO*** change endpoint
pyphi = new $.JsonRpcClient({
  ajaxUrl: 'http://144.92.177.185'
  # 24 hr timeout
  timeout: 86400000
})


getPyphiNetwork = (network) ->
  net =
    'tpm': network.tpm
    'currentState': network.currentState
    'connectivityMatrix': network.getConnectivityMatrix()
    'pastState': network.pastState
  log.debug "PYPHI: Sending network:"
  log.debug net
  return net

# Failure callback.
failure = (err) ->
  log.error err


module.exports =

  complexes: (network, success) ->
    params = [getPyphiNetwork(network)]
    return pyphi.call 'complexes', params, success, failure

  mainComplex: (network, success) ->
    params = [getPyphiNetwork(network)]
    return pyphi.call 'main_complex', params, success, failure

  bigMip: (network, success) ->
    # Get the selected subsystem.
    subsystemIndices = network.getSelectedSubsystem()

    params = [
      subsystemIndices
      getPyphiNetwork(network)
    ]

    return pyphi.call 'big_mip', params, success, failure
