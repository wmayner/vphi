###
# services/graph/mechanism.coffee
###

utils = require './utils'

sum = utils.sum
bit = utils.bit

andGate = (input) ->
  return utils.bit(sum(input) is input.length)

orGate = (input) ->
  return utils.bit(sum(input) >= 1)

parityGate = (input) ->
  return utils.negate(sum(input) % 2)


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
    return utils.bit(sum(input) > (input.length / 2))

  'MIN': (input) ->
    # TODO should this be strictly less than half, or just not a majority?
    return utils.bit(sum(input) <= (input.length / 2))

  'PAR': parityGate

  '>': (input, threshold) ->
    return utils.bit(sum(input) > threshold)

  '<': (input, threshold) ->
    return utils.bit(sum(input) < threshold)

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
