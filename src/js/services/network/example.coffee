###
# graph-editor/example.coffee
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
  unless options.on?
    options.on = 0

  for i in [0...n]
    graph.addNode
      on: options.on
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
  'IIT 3.0 Paper, Fig. 1': ->
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

  'IIT 3.0 Paper, Fig. 17: Specialized majority': ->
    return '/examples/specialized-majority.json'

  'IIT 3.0 Paper, Fig. 17: Homogeneous': ->
    return '/examples/homogeneous.json'

  'IIT 3.0 Paper, Fig. 17: Modular': ->
    return '/examples/modular.json'

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

  '5 OR-node bidirectional loop': ->
    return '/examples/5-OR-bidirectional-loop.json'

  'CA Paper, Fig. 3b: Rule 128, 5 nodes': ->
    return '/examples/cellular-automata-paper_fig-3b_rule-128_5-nodes.json'

  'CA Paper, Fig. 3c: Rule 232, 5 nodes': ->
    return '/examples/cellular-automata-paper_fig-3c_rule-232_5-nodes.json'

  'CA Paper, Fig. 3d: Rule 74, 5 nodes': ->
    return '/examples/cellular-automata-paper_fig-3d_rule-74_5-nodes.json'

  'CA Paper, Fig. 3d: Rule 90, 5 nodes': ->
    return '/examples/cellular-automata-paper_fig-3d_rule-90_5-nodes.json'

  'CA Paper, Fig. 3e: Rule 106, 5 nodes': ->
    return '/examples/cellular-automata-paper_fig-3e_rule-106_5-nodes.json'

  'CA Paper, Fig. 8e: Rule 232, 6 nodes': ->
    return '/examples/cellular-automata-paper_fig-8_rule-232_6-nodes.json'

  # # http://upload.wikimedia.org/wikipedia/commons/c/c6/R-S_mk2.gif
  # 'SR-Latch': ->
  #   graph = new Graph()

  #   # R
  #   graph.addNode
  #     # 0
  #     label: 'R'
  #     on: 0
  #     mechanism: 'OR'
  #     reflexive: false
  #     fixed: true
  #     x: 216
  #     y: 166
  #   # S
  #   graph.addNode
  #     # 1
  #     label: 'S'
  #     on: 0
  #     mechanism: 'OR'
  #     reflexive: false
  #     fixed: true
  #     x: 216
  #     y: 333

  #   # Q
  #   graph.addNode
  #     # 2
  #     label: 'Q'
  #     on: 1
  #     mechanism: 'NOR'
  #     reflexive: false
  #     fixed: true
  #     x: 432
  #     y: 166
  #   # NOT Q
  #   graph.addNode
  #     # 3
  #     label: '¬Q'
  #     on: 0
  #     mechanism: 'NOR'
  #     reflexive: false
  #     fixed: true
  #     x: 432
  #     y: 333

  #   graph.addEdge(0, 2)
  #   graph.addEdge(1, 3)
  #   graph.addEdge(2, 3)
  #   graph.addEdge(3, 2)

  #   return graph


  # 'Gated D-Latch': ->
  #   graph = new Graph()

  #   # Data input
  #   graph.addNode
  #     # 0
  #     label: 'D'
  #     on: 0
  #     mechanism: 'OR'
  #     reflexive: false
  #     fixed: true
  #     x: 160
  #     y: 166
  #   # Enable/Control/Clock input
  #   graph.addNode
  #     # 1
  #     label: 'E'
  #     on: 0
  #     mechanism: 'OR'
  #     reflexive: false
  #     fixed: true
  #     x: 160
  #     y: 333

  #   # Input NANDs
  #   graph.addNode
  #     # 2
  #     label: 'A'
  #     on: 0
  #     mechanism: 'NAND'
  #     reflexive: false
  #     fixed: true
  #     x: 320
  #     y: 166
  #   graph.addNode
  #     # 3
  #     label: 'B'
  #     on: 0
  #     mechanism: 'NAND'
  #     reflexive: false
  #     fixed: true
  #     x: 320
  #     y: 333

  #   # SR Latch NANDs
  #   graph.addNode
  #     # 4
  #     label: 'Q'
  #     on: 0
  #     mechanism: 'NAND'
  #     reflexive: false
  #     fixed: true
  #     x: 480
  #     y: 166
  #   graph.addNode
  #     # 5
  #     label: '¬Q'
  #     on: 1
  #     mechanism: 'NAND'
  #     reflexive: false
  #     fixed: true
  #     x: 480
  #     y: 333

  #   graph.addEdge(0, 2)
  #   graph.addEdge(1, 2)
  #   graph.addEdge(1, 3)
  #   graph.addEdge(2, 3)
  #   graph.addEdge(2, 4)
  #   graph.addEdge(3, 5)
  #   graph.addEdge(4, 5)
  #   graph.addEdge(5, 4)

  #   return graph


module.exports.names = (key for own key, val of module.exports)
