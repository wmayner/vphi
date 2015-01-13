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
exports.chain = (n, options) ->
  for i in [0...n]
    graph.addNode
      on: 0
      mechanism: 'OR'
      reflexive: (if options.reflexive then true else false)

  for i in [0...n]
    if i is n - 1
      if options.circle
        target = 0
      else
        target = null
    else
      target = i + 1
    if target?
      graph.addEdge(i, target)
      if options.bidirectional
        graph.addEdge(target, i)

  graph.setPastState (0 for i in [0...n])

  return graph
