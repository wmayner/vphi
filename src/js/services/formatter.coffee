'use strict'
###
# services/formatter.coffee
###

PRECISION = 5

name = 'vphi.services.formatter'
module.exports = angular.module name, []
  .factory name, ->
    return class Formatter
      constructor: (@getNodeLabel) ->

      # Only return the first 8 characters of the label.
      label: (label) -> label[..8]

      node: (n) ->
        if typeof n is 'number'
          # Node index
          label = @getNodeLabel(n)
        else
          # Node object
          label = n.label
        return @label(label)

      nodes: (indices) -> (@node(i) for i in indices)

      phi: (phiValue) -> d3.round(phiValue, PRECISION)

      time: (seconds) -> d3.round(seconds, 2)

      latexNodes: (indices) -> @nodes(indices).join('') or '[\\,]'
