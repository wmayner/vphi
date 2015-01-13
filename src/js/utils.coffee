###
# utils.coffee
###

PRECISION = 6

module.exports =

  # Alphabet for letter labels of nodes.
  LABEL: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
          'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

  formatPhi: (phiValue) -> d3.round(phiValue, PRECISION)

  formatCut: (cut) ->
    if cut.severed.length is 0
      return 'N/A'
    intact = @formatNodes(cut.intact) or '[]'
    severed = @formatNodes(cut.severed) or '[]'
    return "#{severed} ⇏ #{intact}"

  formatNodes: (nodeArray) ->
    return (@LABEL[n] for n in nodeArray).join(' ')

  latexNodes: (nodeArray) -> @formatNodes(nodeArray) or '[\\,]'

  holiIndexToState: (i, numberOfNodes) ->
    # Convert a decimal index into an array of binary node states according to
    # the HOLI convention (high-order bits correspond to low-index nodes).
    return ((i >> n) & 1 for n in [0...numberOfNodes])

  loliIndexToState: (i, numberOfNodes) ->
    # Convert a decimal index into an array of binary node states according to
    # the LOLI convention (low-order bits correspond to low-index nodes).
    return @holiIndexToState(i, numberOfNodes).reverse()
