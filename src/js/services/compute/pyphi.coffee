###
# pyphi.coffee
#
# API for PyPhi's RPC server.
###

# TODO*** change endpoint
pyphi = new $.JsonRpcClient({
  ajaxUrl: 'http://144.92.177.185'
  # 12 hr timeout
  timeout: 43200000
})


getPyphiNetwork = (network) ->
  net =
    'tpm': network.tpm
    'cm': network.cm
    'state': network.state
  log.debug "PYPHI: Sending network:"
  log.debug net
  return net

# Failure callback.
defaultFailure = (err) ->
  log.error err


module.exports =

  complexes: (network, success, failure = defaultFailure) ->
    params = [getPyphiNetwork(network)]
    return pyphi.call 'complexes', params, success, failure

  mainComplex: (network, success, failure = defaultFailure) ->
    params = [getPyphiNetwork(network)]
    return pyphi.call 'main_complex', params, success, failure

  bigMip: (network, success, failure = defaultFailure) ->
    # Get the selected subsystem.
    subsystemIndices = network.getSelectedSubsystem()

    params = [
      subsystemIndices
      getPyphiNetwork(network)
    ]

    return pyphi.call 'big_mip', params, success, failure
