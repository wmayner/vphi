###
# utils.coffee
###

log = require 'loglevel'


module.exports =

  # Alphabet for letter labels of nodes.
  LABEL: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
          'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

  loliIndexToState: (i, numNodes) ->
    # Convert a decimal index into an array of binary node states according to
    # the HOLI convention (high-order bits correspond to low-index nodes).
    return ((i >> n) & 1 for n in [0...numNodes])

  holiIndexToState: (i, numNodes) ->
    # Convert a decimal index into an array of binary node states according to
    # the LOLI convention (low-order bits correspond to low-index nodes).
    return @loliIndexToState(i, numNodes).reverse()

  allStates: (numNodes) ->
    # Return all states in LOLI order
    return (@loliIndexToState(i, numNodes) for i in [0...Math.pow(2, numNodes)])

  logTpm: (tpm) ->
    log.debug "---------------"
    n = tpm[0].length
    for i in [0...tpm.length]
      log.debug "#{@loliIndexToState(i, n)} -> #{tpm[i]}"
    log.debug "---------------"

  stateReachable: (state, tpm) ->
    test = ((row[j] - state[j] for j in [0...state.length]) for row in tpm)
    return test.some (row) -> row.every (entry) -> (-1 < entry < 1)

  semverCompare: (a, b) ->
    # From https://github.com/substack/semver-compare
    pa = a.split('.')
    pb = b.split('.')
    i = 0
    while i < 3
      na = Number(pa[i])
      nb = Number(pb[i])
      if na > nb
        return 1
      if nb > na
        return -1
      if !isNaN(na) and isNaN(nb)
        return 1
      if isNaN(na) and !isNaN(nb)
        return -1
      i++
    return 0
