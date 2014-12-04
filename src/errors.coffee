module.exports =

  STATE_UNREACHABLE: 1

  NETWORK_SIZE_LIMIT: 2

  stateUnreachable: ->
    e = new Error("Current state cannot be reached by any past state.")
    e.code = 1
    return e

  networkSizeLimit: (limit) ->
    e = new Error("Network cannot have more than #{limit} nodes.")
    e.code = 2
    return e
