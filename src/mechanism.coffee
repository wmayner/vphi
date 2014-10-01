# Functions that nodes can implement

bit = (bool) -> (if bool then 1 else 0)

parity = (input) ->
  sum = 0
  sum += i for i in input
  return (if sum % 2 is 0 then 1 else 0)

module.exports =
  'AND': (input) ->
    sum = 0
    sum += i for i in input
    return bit(sum is input.length)
  'OR': (input) ->
    sum = 0
    sum += i for i in input
    return bit(sum >= 1)
  'XOR': (input) ->
    # TODO document that XOR here means the parity interpretation
    return bit(not parity(input))
  'COPY': (input) ->
    # TODO define behavior
    return input[0]
  'NOT': (input) ->
    # TODO define behavior
    return bit(not input[0])
  'NULL': (input) ->
    return Math.random() < 0.5
  'MAJORITY': (input) ->
    sum = 0
    sum += i for i in input
    return bit(sum > (input.length / 2))
  'MINORITY': (input) ->
    # TODO should this be strictly less than half, or just not a majority?
    sum = 0
    sum += i for i in input
    return bit(sum <= (input.length / 2))
  'PARITY': parity
  'THRESHOLD':
    'ABOVE': (n, input) ->
      sum = 0
      sum += i for i in input
      return bit(sum > n)
    'BELOW': (n, input) ->
      sum = 0
      sum += i for i in input
      return bit(sum < n)
