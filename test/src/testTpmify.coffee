Graph = require '../../lib/digraph'
mechanism = require '../../lib/mechanism'
tpmify = require '../../lib/tpmify'

describe 'tpmify', ->
  # Standard Matlab 3-node example
  graph = new Graph()
  graph.addNode({mechanism: mechanism['OR']})
  graph.addNode({mechanism: mechanism['COPY']})
  graph.addNode({mechanism: mechanism['XOR']})
  graph.addEdge(0, 2)
  graph.addEdge(1, 0)
  graph.addEdge(1, 2)
  graph.addEdge(2, 0)
  graph.addEdge(2, 1)
  # The corresponding TPM
  answer = {
    '0,0,0': {0: 0, 1: 0, 2: 0}
    '1,0,0': {0: 0, 1: 0, 2: 1}
    '0,1,0': {0: 1, 1: 0, 2: 1}
    '1,1,0': {0: 1, 1: 0, 2: 0}
    '0,0,1': {0: 1, 1: 1, 2: 0}
    '1,0,1': {0: 1, 1: 1, 2: 1}
    '0,1,1': {0: 1, 1: 1, 2: 1}
    '1,1,1': {0: 1, 1: 1, 2: 0}
  }

  it 'should convert the graph to the correct TPM', ->
    tpmify(graph).should.eql answer
  it 'should work after removing and adding nodes', ->
    graph.removeNode(0)
    newId = graph.addNode({mechanism: mechanism['OR']})._id
    graph.getNode(1).label = 1
    graph.getNode(2).label = 2
    newId.label = 0
    console.log newId
    graph.addEdge(newId, 2)
    graph.addEdge(1, newId)
    graph.addEdge(2, newId)
    tpmify(graph).should.eql answer
