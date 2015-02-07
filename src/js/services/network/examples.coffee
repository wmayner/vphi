###
# graph-editor/examples.coffee
###

Graph = require './graph'

# TODO Refactor graph to take a bunch of edges


# N-chain
# options:
#   k: connections to next k neighbors
#   circle: chain is a loop
#   reflexive: nodes have self-loops
#   bidirectional: connections are bidirectional
chain = (n, options) ->
  graph = new Graph()

  unless options.k?
    options.k = 1

  for i in [0...n]
    graph.addNode
      on: 0
      mechanism: options.mechanism or 'OR'
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

  return graph


module.exports =

  # IIT 3.0 paper example
  'IIT 2014 Paper': ->
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

    return graph

  # Matlab default example
  'IIT 2008 Paper': ->
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

    return graph


  # http://upload.wikimedia.org/wikipedia/commons/c/c6/R-S_mk2.gif
  'SR-Latch': ->
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

    return graph


  'Gated D-Latch': ->
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

    return graph


  '5 OR-node bidirectional loop': ->
    chain 5,
      k: 1
      circle: true
      mechanism: 'OR'
      reflexive: false
      bidirectional: true


  '5 OR-node bidirectional loop, k = 2': ->
    chain 5,
      k: 2
      circle: true
      mechanism: 'OR'
      reflexive: false
      bidirectional: true
