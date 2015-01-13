###
# graph-editor/examples.coffee
###

Graph = require './graph'
controls = require './controls'

graph = new Graph()

# Bind the controls to the graph.
graph.controls = controls

# IIT 3.0 paper example
exports.paper = ->
  graph.addNode
    on: 1
    mechanism: 'OR'
    reflexive: false
  graph.addNode
    on: 0
    mechanism: 'AND'
    reflexive: false
  graph.addNode
    on: 0
    mechanism: 'XOR'
    reflexive: false

  graph.addEdge(0, 2)
  graph.addEdge(0, 1)
  graph.addEdge(1, 0)
  graph.addEdge(1, 2)
  graph.addEdge(2, 0)
  graph.addEdge(2, 1)

  graph.setPastState([1, 1, 0])

  return graph


# N-node chain
#
# Options:
#   circle - chain is a loop
#   reflexive - all nodes reflexive
#   bidirectional - all edges bidirectional
#   k - number of following nodes in the chain to connect to (default 1)
exports.chain = (n, options) ->
  unless options.k?
    options.k = 1

  for i in [0...n]
    graph.addNode
      on: 0
      mechanism: 'OR'
      reflexive: (if options.reflexive then true else false)

  for i in [0...n]
    for j in [0...options.k]
      target = i + 1 + j
      if target >= n
        if options.circle
          target %= n
        else target = null
      if target?
        graph.addEdge(i, target)
        if options.bidirectional
          graph.addEdge(target, i)

  graph.setPastState (0 for i in [0...n])

  return graph
