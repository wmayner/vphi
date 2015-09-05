###
# utils.coffee
###

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
    return @holiIndexToState(i, numNodes).reverse()

  logTpm: (tpm) ->
    log.debug "---------------"
    n = tpm[0].length
    for i in [0...tpm.length]
      log.debug "#{@loliIndexToState(i, n)} -> #{tpm[i]}"
    log.debug "---------------"
