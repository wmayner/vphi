module.exports =

  indexToState: (i, numberOfNodes) ->
    # Convert a decimal index into an array of binary node states.
    # Low-index nodes / High-order bits vary the fastest.
    return ((i >> n) & 1 for n in [0...numberOfNodes])
