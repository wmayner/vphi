###
# graph-editor/examples.coffee
###

Graph = require './graph'

# IIT 3.0 paper example
exports.paper = ->
  graph = new Graph()

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

  graph.setPastState graph.getPossiblePastStates()[0]

  return graph

# Matlab default example
exports.matlab = ->
  graph = new Graph()

  graph.addNode
    on: 1
    mechanism: 'OR'
    reflexive: false
  graph.addNode
    on: 0
    mechanism: 'OR'
    reflexive: false
  graph.addNode
    on: 0
    mechanism: 'XOR'
    reflexive: false

  graph.addEdge(0, 2)
  graph.addEdge(1, 0)
  graph.addEdge(1, 2)
  graph.addEdge(2, 0)
  graph.addEdge(2, 1)

  graph.setPastState graph.getPossiblePastStates()[0]

  return graph


# N-node chain
#
# Options:
#   circle - chain is a loop
#   reflexive - all nodes reflexive
#   bidirectional - all edges bidirectional
#   k - number of following nodes in the chain to connect to (default 1)
exports.chain = (n, options) ->
  graph = new Graph()

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

  graph.setPastState graph.getPossiblePastStates()[0]

  return graph


exports.threshold = ->
  graph = new Graph()

  graph.addNode
    on: 0
    mechanism: 'OR'
    reflexive: false
  graph.addNode
    on: 0
    mechanism: 'OR'
    reflexive: false
  graph.addNode
    on: 1
    mechanism: '>'
    threshold: 1
    reflexive: false

  graph.addEdge(0, 2)
  graph.addEdge(1, 2)

  graph.setPastState graph.getPossiblePastStates()[0]

  return graph


# http://upload.wikimedia.org/wikipedia/commons/c/c6/R-S_mk2.gif
exports.srLatch = ->
  graph = new Graph()

  # R
  graph.addNode
    # 0
    label: 'R'
    on: 0
    mechanism: 'OR'
    reflexive: false
    fixed: true
    x: 216
    y: 166
  # S
  graph.addNode
    # 1
    label: 'S'
    on: 0
    mechanism: 'OR'
    reflexive: false
    fixed: true
    x: 216
    y: 333

  # Q
  graph.addNode
    # 2
    label: 'Q'
    on: 1
    mechanism: 'NOR'
    reflexive: false
    fixed: true
    x: 432
    y: 166
  # NOT Q
  graph.addNode
    # 3
    label: '¬Q'
    on: 0
    mechanism: 'NOR'
    reflexive: false
    fixed: true
    x: 432
    y: 333

  graph.addEdge(0, 2)
  graph.addEdge(1, 3)
  graph.addEdge(2, 3)
  graph.addEdge(3, 2)

  graph.setPastState graph.getPossiblePastStates()[0]

  return graph


exports.gatedDLatch = ->
  graph = new Graph()

  # Data input
  graph.addNode
    # 0
    label: 'D'
    on: 0
    mechanism: 'OR'
    reflexive: false
    fixed: true
    x: 160
    y: 166
  # Enable/Control/Clock input
  graph.addNode
    # 1
    label: 'E'
    on: 0
    mechanism: 'OR'
    reflexive: false
    fixed: true
    x: 160
    y: 333

  # Input NANDs
  graph.addNode
    # 2
    label: 'A'
    on: 0
    mechanism: 'NAND'
    reflexive: false
    fixed: true
    x: 320
    y: 166
  graph.addNode
    # 3
    label: 'B'
    on: 0
    mechanism: 'NAND'
    reflexive: false
    fixed: true
    x: 320
    y: 333

  # SR Latch NANDs
  graph.addNode
    # 4
    label: 'Q'
    on: 0
    mechanism: 'NAND'
    reflexive: false
    fixed: true
    x: 480
    y: 166
  graph.addNode
    # 5
    label: '¬Q'
    on: 1
    mechanism: 'NAND'
    reflexive: false
    fixed: true
    x: 480
    y: 333

  graph.addEdge(0, 2)
  graph.addEdge(1, 2)
  graph.addEdge(1, 3)
  graph.addEdge(2, 3)
  graph.addEdge(2, 4)
  graph.addEdge(3, 5)
  graph.addEdge(4, 5)
  graph.addEdge(5, 4)

  graph.setPastState graph.getPossiblePastStates()[0]

  return graph
