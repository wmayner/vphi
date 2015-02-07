###
# services/graph/mechanism.coffee
###

utils = require './utils'

andGate = (input) ->
    sum = 0
    sum += i for i in input
    return utils.bit(sum is input.length)
orGate = (input) ->
    sum = 0
    sum += i for i in input
    return utils.bit(sum >= 1)
parityGate = (input) ->
  sum = 0
  sum += i for i in input
  return utils.negate(sum % 2)


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
  '>'
  '<'
]

exports.functions =
  'AND': andGate
  'NAND': (input) ->
    return utils.negate(andGate(input))
  'OR': orGate
  'NOR': (input) ->
    return utils.negate(orGate(input))
  'XOR': (input) ->
    # TODO document that XOR here means the parity interpretation
    return utils.bit(not parityGate(input))
  'RAND': (input) ->
    return Math.random() < 0.5
  'MAJ': (input) ->
    sum = 0
    sum += i for i in input
    return utils.bit(sum > (input.length / 2))
  'MIN': (input) ->
    # TODO should this be strictly less than half, or just not a majority?
    sum = 0
    sum += i for i in input
    return utils.bit(sum <= (input.length / 2))
  'PAR': parityGate
  '>': (input, threshold) ->
    sum = 0
    sum += i for i in input
    return utils.bit(sum > threshold)
  '<': (input, threshold) ->
    sum = 0
    sum += i for i in input
    return utils.bit(sum < threshold)
