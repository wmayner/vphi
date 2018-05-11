###
# pyphi.coffee
#
# API for PyPhi's RPC server.
###

log = require 'loglevel'

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


# RPC interface to phiserver.
class PyphiService

  constructor: (url) ->
    @pyphi = new $.JsonRpcClient({
      ajaxUrl: url
      # 12 hr timeout
      timeout: 43200000
    })

  complexes: (network, success, failure = defaultFailure) ->
    params = [getPyphiNetwork(network)]
    return @pyphi.call 'complexes', params, success, failure

  mainComplex: (network, success, failure = defaultFailure) ->
    params = [getPyphiNetwork(network)]
    return @pyphi.call 'main_complex', params, success, failure

  bigMip: (network, success, failure = defaultFailure) ->
    # Get the selected subsystem.
    params = [
      network.getSelectedSubsystem()
      getPyphiNetwork(network)
    ]
    return @pyphi.call 'big_mip', params, success, failure


name = 'vphi.services.compute.pyphi'
module.exports = angular.module name, []
  .service name, ['PHISERVER_URL', PyphiService]
