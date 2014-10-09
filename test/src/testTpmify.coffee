Graph = require '../../lib/digraph'
mechanism = require '../../lib/mechanism'
tpmify = require '../../lib/tpmify'

describe 'tpmify', ->

  # Standard Matlab 3-node example
  graph = new Graph()
  graph.addNode({mechanism: mechanism["OR"]})
  graph.addNode({mechanism: mechanism["COPY"]})
  graph.addNode({mechanism: mechanism["XOR"]})
  graph.addEdge(0, 2)
  graph.addEdge(1, 0)
  graph.addEdge(1, 2)
  graph.addEdge(2, 0)
  graph.addEdge(2, 1)

  it 'should convert the graph to the correct TPM', ->
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
    tpmify(graph).should.eql answer
