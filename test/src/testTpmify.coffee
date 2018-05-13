Graph = require '../../src/js/services/network/graph'
mechanism = require '../../src/js/services/network/mechanism'
network = require '../../src/js/services/network'

describe 'tpmify', ->

  # Standard Matlab 3-node example
  graph = new Graph()
  orNode = graph.addNode({mechanism: 'OR'})
  copyNode = graph.addNode({mechanism: 'COPY'})
  xorNode = graph.addNode({mechanism: 'XOR'})
  graph.addEdge(0, 2)
  graph.addEdge(1, 0)
  graph.addEdge(1, 2)
  graph.addEdge(2, 0)
  graph.addEdge(2, 1)
  # The corresponding TPM
  answer = [
    [0, 0, 0],
    [0, 0, 1],
    [1, 0, 1],
    [1, 0, 0],
    [1, 1, 0],
    [1, 1, 1],
    [1, 1, 1],
    [1, 1, 0]
  ]

  it 'should convert the graph to the correct TPM', ->
    graph.tpmify().should.eql answer
  it 'should work after removing and adding nodes', ->
    graph.removeNode(xorNode)
    newNode = graph.addNode({mechanism: 'XOR'})
    graph.addEdge(newNode._id, orNode._id)
    graph.addEdge(newNode._id, copyNode._id)
    graph.addEdge(orNode._id, newNode._id)
    graph.addEdge(copyNode._id, newNode._id)
    graph.tpmify().should.eql answer
