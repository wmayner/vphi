###
# graph-editor/utils.coffee
###


module.exports =

  bit: (bool) -> (if bool then 1 else 0)

  negate: (bool) -> (if bool then 0 else 1)

  sum: (input) ->
    sum = 0
    sum += i for i in input
    return sum
