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


module.exports =
  'AND': andGate
  'NAND': (input) ->
    return utils.negate(andGate(input))
  'OR': orGate
  'NOR': (input) ->
    return utils.negate(orGate(input))
  'XOR': (input) ->
    # TODO document that XOR here means the parity interpretation
    return utils.negate(parityGate(input))
  'RAND': (input) ->
    return utils.bit(Math.random() < 0.5)
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

keys = (key for own key, val of module.exports)
module.exports.keys = keys
module.exports.names =
  'AND': 'AND Gate'
  'NAND': 'NAND Gate'
  'OR': 'OR Gate'
  'NOR': 'NOR Gate'
  'XOR': 'XOR Gate'
  'RAND': 'Random'
  'MAJ': 'Majority'
  'MIN': 'Minority'
  'PAR': 'Parity'
  '>': 'Greater than threshold'
  '<': 'Less than threshold'
