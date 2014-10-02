should = require 'should'
sinon = require 'sinon'

Graph = require('../src/digraph')

# Shorthand for logging.
l = (x) -> console.log require('util').inspect x, true, 10

addNodesTo = (graph, addEdges = no) ->
  initNodeSize = graph.nodeSize
  graph.addNode '1'
  graph.addNode '2'
  graph.addNode '3'
  graph.addNode '4'
  graph.addNode '5'
  graph.addNode '6'
  graph.nodeSize.should.be.exactly initNodeSize + 6
  if addEdges
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    initEdgeSize = graph.edgeSize
    initEdgeSize.should.be.exactly 0
    graph.addEdge '1', '4', 9
    graph.addEdge '2', '1', 9
    graph.addEdge '2', '3', 9
    graph.addEdge '3', '2', 9
    graph.addEdge '5', '1', 9
    graph.addEdge '5', '2', 9
    graph.addEdge '6', '3', 9
    graph.addEdge '6', '6', 9
    graph.edgeSize.should.be.exactly initEdgeSize + 8

describe 'Add node', ->
  graph = new Graph()
  it 'should have 0 edge and 0 node initially', ->
    graph.nodeSize.should.be.exactly 0
    graph.edgeSize.should.be.exactly 0
  it 'should return the node object added, or undefined if the id exists', ->
    graph.addNode('item').should.be.type 'object'
    graph.addNode('1').should.be.type 'object'
    graph.addNode(null).should.be.type 'object'
  it "should return undefined if the node id already exists", ->
    should.not.exist graph.addNode('item')
    should.not.exist graph.addNode('1')
    should.not.exist graph.addNode(null)
  it "should have kept the node size constant with non-insertions", ->
    graph.nodeSize.should.eql 3

describe "Get node", ->
  graph = new Graph()
  it "should return undefined if the node's not found", ->
    should.not.exist graph.getNode(null)
    should.not.exist graph.getNode(undefined)
    should.not.exist graph.getNode(2)
  it "should return the added node", ->
    addNodesTo graph
    graph.getNode('1').should.be.type 'object'
    graph.getNode('2').should.be.type 'object'
    graph.getNode('6').should.be.type 'object'
  it "should return a defined object if null and undefined are found", ->
    graph.addNode null
    graph.addNode undefined
    graph.getNode(null).should.be.type 'object'
    graph.getNode(undefined).should.be.type 'object'

describe "Remove node", ->
  graph = new Graph()
  it "should return undefined if the node doesn't exist in the first place", ->
    should.not.exist graph.removeNode(null)
    should.not.exist graph.removeNode(2)
  it "should have kept the node size constant", ->
    graph.nodeSize.should.eql 0
  it "should return the value of node removed", ->
    addNodesTo graph
    graph.removeNode("1").should.be.type 'object'
    graph.removeNode("3").should.be.type 'object'
    graph.removeNode("6").should.be.type 'object'
  it "should have updated the node size", ->
    graph.nodeSize.should.be.exactly 3
  it "should have removed the node", ->
    should.not.exist graph.getNode("1")
    should.not.exist graph.getNode("3")
    should.not.exist graph.getNode("6")

describe "Add edge", ->
  graph = new Graph()
  it "should return undefined if either/both nodes don't exist in the graph", ->
    should.not.exist graph.addEdge("7", "8")
    should.not.exist graph.addEdge("1", "8")
    should.not.exist graph.addEdge("99", "1")
    addNodesTo graph
    should.not.exist graph.addEdge("7", "8")
    should.not.exist graph.addEdge("1", "8")
    should.not.exist graph.addEdge("99", "1")
  it "should add the edge and return the edge object", ->
    graph.addEdge("1", "2").should.be.type 'object'
    graph.addEdge("2", "1").should.be.type 'object'
    graph.addEdge("3", "2").should.be.type 'object'
  it "should have updated the edge size", ->
    graph.edgeSize.should.be.exactly 3
  it "should have initiated the edge weight to 1", ->
    graph.addEdge("5", "2").weight.should.be.exactly 1
    graph.addEdge("5", "6").weight.should.be.exactly 1
    graph.addEdge("3", "6").weight.should.be.exactly 1
  it "should allow the node to add an edge to itself", ->
    graph.addEdge("2", "2").should.be.type 'object'
    graph.addEdge("6", "6").should.be.type 'object'
  it "should count a self-directing edge as a single one", ->
    graph.edgeSize.should.be.exactly 8
  it "should return undefined if the edge already exists", ->
    should.not.exist graph.addEdge("1", "2")
    should.not.exist graph.addEdge("2", "2")
    should.not.exist graph.addEdge("2", "1")

describe "Get edge", ->
  graph = new Graph()
  it "should return undefined if the nodes aren't found", ->
    should.not.exist graph.getEdge("1", "2")
  it "should return undefined if the edge isn't found", ->
    addNodesTo graph, yes
    should.not.exist graph.getEdge("3", "5")
    should.not.exist graph.getEdge("1", "2")
  it "should return the edge found", ->
    graph.getEdge("1", "4").should.be.type 'object'
    graph.getEdge("2", "1").should.be.type 'object'
    graph.getEdge("2", "3").should.be.type 'object'
    graph.getEdge("3", "2").should.be.type 'object'
    graph.getEdge("5", "1").should.be.type 'object'
    graph.getEdge("5", "2").should.be.type 'object'
    graph.getEdge("6", "3").should.be.type 'object'
    graph.getEdge("6", "6").should.be.type 'object'

describe "Remove edge", ->
  graph = new Graph()
  it "should return undefined if either node's not found", ->
    should.not.exist graph.removeEdge(1, 2)
    should.not.exist graph.removeEdge(undefined, undefined)
  it "should have kept the edge count at 0", ->
    graph.edgeSize.should.be.exactly 0
  it "should return undefined if the edge doesn't exist", ->
    addNodesTo graph, yes
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    graph.removeEdge("1", "4").weight.should.be.exactly 9
    graph.removeEdge("2", "1").weight.should.be.exactly 9
    graph.removeEdge("2", "3").weight.should.be.exactly 9
    graph.removeEdge("3", "2").weight.should.be.exactly 9
    graph.removeEdge("5", "1").weight.should.be.exactly 9
    graph.removeEdge("5", "2").weight.should.be.exactly 9
    graph.removeEdge("6", "3").weight.should.be.exactly 9
  it "should have kept track of the edge count", ->
    graph.edgeSize.should.be.exactly 1
  it "should remove a self-directing correctly", ->
    graph.removeEdge("6", "6").weight.should.be.exactly 9
    graph.edgeSize.should.be.exactly 0
  it "should leave an empty graph after removing all the edges", ->
    should.not.exist graph.removeEdge("1", "4")
    should.not.exist graph.removeEdge("2", "1")
    should.not.exist graph.removeEdge("2", "3")
    should.not.exist graph.removeEdge("3", "2")
    should.not.exist graph.removeEdge("5", "1")
    should.not.exist graph.removeEdge("5", "2")
    should.not.exist graph.removeEdge("6", "3")
    should.not.exist graph.removeEdge("6", "6")

describe "Get all in edges", ->
  graph = new Graph()
  it "should return empty array for a non-existant node", ->
    graph.getOutEdgesOf("6").should.eql []
    graph.getOutEdgesOf(undefined).should.eql []
  it "should return empty array for no edges", ->
    addNodesTo graph
    graph.getInEdgesOf("1").should.eql []
    graph.getInEdgesOf("2").should.eql []
    graph.getInEdgesOf("6").should.eql []
  graph2 = new Graph()
  it "should return the in edges", ->
    addNodesTo graph2, yes
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    graph2.getInEdgesOf("1").length.should.be.exactly 2
    graph2.getInEdgesOf("1").should.containEql graph2.getEdge("2", "1")
    graph2.getInEdgesOf("1").should.containEql graph2.getEdge("5", "1")

    graph2.getInEdgesOf("2").length.should.be.exactly 2
    graph2.getInEdgesOf("2").should.containEql graph2.getEdge("3", "2")
    graph2.getInEdgesOf("2").should.containEql graph2.getEdge("5", "2")

    graph2.getInEdgesOf("3").length.should.be.exactly 2
    graph2.getInEdgesOf("3").should.containEql graph2.getEdge("2", "3")
    graph2.getInEdgesOf("3").should.containEql graph2.getEdge("6", "3")

    graph2.getInEdgesOf("4").length.should.be.exactly 1
    graph2.getInEdgesOf("4").should.containEql graph2.getEdge("1", "4")

    graph2.getInEdgesOf("5").should.eql []
    graph2.getInEdgesOf("6").length.should.be.exactly 1
    graph2.getInEdgesOf("6").should.containEql graph2.getEdge("6", "6")

describe "Get all out edges", ->
  graph = new Graph()
  it "should return empty array for a non-existant node", ->
    graph.getOutEdgesOf("6").should.eql []
    graph.getOutEdgesOf(undefined).should.eql []
  it "should return empty array for no edges", ->
    addNodesTo graph
    graph.getOutEdgesOf("1").should.eql []
    graph.getOutEdgesOf("2").should.eql []
  graph2 = new Graph()
  it "should return the in edges", ->
    addNodesTo graph2, yes
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    graph2.getOutEdgesOf("1").length.should.be.exactly 1
    graph2.getOutEdgesOf("1").should.containEql graph2.getEdge("1", "4")

    graph2.getOutEdgesOf("2").length.should.be.exactly 2
    graph2.getOutEdgesOf("2").should.containEql graph2.getEdge("2", "1")
    graph2.getOutEdgesOf("2").should.containEql graph2.getEdge("2", "3")

    graph2.getOutEdgesOf("3").length.should.be.exactly 1
    graph2.getOutEdgesOf("3").should.containEql graph2.getEdge("3", "2")

    graph2.getOutEdgesOf("4").should.eql []

    graph2.getOutEdgesOf("5").length.should.be.exactly 2
    graph2.getOutEdgesOf("5").should.containEql graph2.getEdge("5", "1")
    graph2.getOutEdgesOf("5").should.containEql graph2.getEdge("5", "2")

    graph2.getOutEdgesOf("6").length.should.be.exactly 2
    graph2.getOutEdgesOf("6").should.containEql graph2.getEdge("6", "3")
    graph2.getOutEdgesOf("6").should.containEql graph2.getEdge("6", "6")

describe "Get all edges", ->
  graph = new Graph()
  it "should return an empty array if node doesn't exist", ->
    graph.getAllEdgesOf(1).should.eql []
    graph.getAllEdgesOf(undefined).should.eql []
  it "should return an empty array if the node doesn't have edges", ->
    addNodesTo graph
    graph.getAllEdgesOf("1").should.eql []
    graph.getAllEdgesOf("2").should.eql []
    graph.getAllEdgesOf("6").should.eql []
  graph2 = new Graph()
  it "should return an array of edges", ->
    addNodesTo graph2, yes
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    graph2.getAllEdgesOf("1").length.should.be.exactly 3
    graph2.getAllEdgesOf("1").should.containEql graph2.getEdge("1", "4")
    graph2.getAllEdgesOf("1").should.containEql graph2.getEdge("2", "1")
    graph2.getAllEdgesOf("1").should.containEql graph2.getEdge("5", "1")

    graph2.getAllEdgesOf("2").length.should.be.exactly 4
    graph2.getAllEdgesOf("2").should.containEql graph2.getEdge("2", "1")
    graph2.getAllEdgesOf("2").should.containEql graph2.getEdge("2", "3")
    graph2.getAllEdgesOf("2").should.containEql graph2.getEdge("3", "2")
    graph2.getAllEdgesOf("2").should.containEql graph2.getEdge("5", "2")

    graph2.getAllEdgesOf("3").length.should.be.exactly 3
    graph2.getAllEdgesOf("3").should.containEql graph2.getEdge("3", "2")
    graph2.getAllEdgesOf("3").should.containEql graph2.getEdge("2", "3")
    graph2.getAllEdgesOf("3").should.containEql graph2.getEdge("6", "3")

    graph2.getAllEdgesOf("4").length.should.be.exactly 1
    graph2.getAllEdgesOf("4").should.containEql graph2.getEdge("1", "4")

    graph2.getAllEdgesOf("5").length.should.be.exactly 2
    graph2.getAllEdgesOf("5").should.containEql graph2.getEdge("5", "1")
    graph2.getAllEdgesOf("5").should.containEql graph2.getEdge("5", "2")
  it "should not duplicate a self-pointing edge", ->
    graph2.getAllEdgesOf("6").length.should.be.exactly 2
    graph2.getAllEdgesOf("6").should.containEql graph2.getEdge("6", "3")
    graph2.getAllEdgesOf("6").should.containEql graph2.getEdge("6", "6")

describe "Traverse through each node", ->
  graph = new Graph()
  it "shouldn't call the callback for an empty graph", ->
    callback = sinon.spy()
    graph.forEachNode callback
    callback.called.should.be.false
  it "should reach each node once", ->
    addNodesTo graph
    callback = sinon.spy()
    graph.forEachNode callback
    callback.callCount.should.be.exactly 6
  it "should pass nodeObject and nodeId to the callback", ->
    callback = sinon.spy()
    graph.forEachNode callback
    lastCallArgs = callback.args[callback.callCount - 1]
    lastCallArgs[0].should.be.type 'object'
    lastCallArgs[1].should.be.exactly '6'

describe "Traverse through each edge", ->
  graph = new Graph()
  it "shouldn't call the callback for an empty graph", ->
    callback = sinon.spy()
    graph.forEachEdge callback
    callback.called.should.be.false
  it "should reach each edge once", ->
    addNodesTo graph, yes
    callback = sinon.spy()
    graph.forEachEdge callback
    callback.callCount.should.be.exactly 8
  it "should reach the isolated node with an edge toward itself", ->
    graph.addNode "99"
    graph.addEdge "99", "99", 999
    callback = sinon.spy()
    graph.forEachEdge callback
    callback.callCount.should.be.exactly 9
