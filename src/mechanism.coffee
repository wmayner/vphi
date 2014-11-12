# Logical functions that nodes can implement

bit = (bool) -> (if bool then 1 else 0)
negate = (bool) -> (if bool then 0 else 1)

andGate = (input) ->
    sum = 0
    sum += i for i in input
    return bit(sum is input.length)
orGate = (input) ->
    sum = 0
    sum += i for i in input
    return bit(sum >= 1)
parityGate = (input) ->
  sum = 0
  sum += i for i in input
  return negate(sum % 2)


exports.names = [
  'AND'
  'NAND'
  'OR'
  'NOR'
  'XOR'
  'RAND'
  'MAJ'
  'MIN'
  'PAR'
  'THRESH'
]
exports.functions =
  'AND': andGate
  'NAND': (input) ->
    return negate(andGate(input))
  'OR': orGate
  'NOR': (input) ->
    return negate(orGate(input))
  'XOR': (input) ->
    # TODO document that XOR here means the parity interpretation
    return bit(not parityGate(input))
  'RAND': (input) ->
    return Math.random() < 0.5
  'MAJ': (input) ->
    sum = 0
    sum += i for i in input
    return bit(sum > (input.length / 2))
  'MIN': (input) ->
    # TODO should this be strictly less than half, or just not a majority?
    sum = 0
    sum += i for i in input
    return bit(sum <= (input.length / 2))
  'PAR': parityGate
  'THRESH':
    'ABOVE': (n, input) ->
      sum = 0
      sum += i for i in input
      return bit(sum > n)
    'BELOW': (n, input) ->
      sum = 0
      sum += i for i in input
      return bit(sum < n)
