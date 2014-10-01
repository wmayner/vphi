assert = require 'assert'
Graph = require "../src/digraph.coffee"
mechanism = require '../src/mechanism.coffee'

tpmify = require '../src/tpmify.coffee'

describe 'tpmify', ->

  # Standard Matlab 3-node example
  graph = new Graph()
  graph.addNode('0', 1)
    .mechanism = mechanism["OR"]
  graph.addNode('1', 0)
    .mechanism = mechanism["COPY"]
  graph.addNode('2', 0)
    .mechanism = mechanism["XOR"]
  graph.addEdge(0, 2)
  graph.addEdge(1, 0)
  graph.addEdge(1, 2)
  graph.addEdge(2, 0)
  graph.addEdge(2, 1)

  console.log graph.getInEdgesOf('0')

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
    assert.deepEqual answer, tpmify(graph)
