Graph = require '../../lib/digraph'

# Shorthand for logging.
l = (x) -> console.log require('util').inspect x, true, 10

addNodesTo = (graph, addEdges = no) ->
  initNodeSize = graph.nodeSize
  graph.addNode()
  graph.addNode()
  graph.addNode()
  graph.addNode()
  graph.addNode()
  graph.addNode()
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
    graph.addEdge '0', '3', 9
    graph.addEdge '1', '0', 9
    graph.addEdge '1', '2', 9
    graph.addEdge '2', '1', 9
    graph.addEdge '4', '0', 9
    graph.addEdge '4', '1', 9
    graph.addEdge '5', '2', 9
    graph.addEdge '5', '5', 9
    graph.edgeSize.should.be.exactly initEdgeSize + 8

describe 'Add node', ->
  graph = new Graph()
  it 'should have 0 edge and 0 node initially', ->
    graph.nodeSize.should.be.exactly 0
    graph.edgeSize.should.be.exactly 0
    return
  it 'should return the node object added', ->
    graph.addNode().should.be.type 'object'
    graph.addNode({label: 'A'}).should.be.type 'object'
    return
  it "should have kept the node size constant with non-insertions", ->
    graph.nodeSize.should.eql 2
    return
  return

describe "Get node", ->
  graph = new Graph()
  it "should return undefined if the node's not found", ->
    Should.not.exist graph.getNode(null)
    Should.not.exist graph.getNode(undefined)
    Should.not.exist graph.getNode(2)
    return
  it "should return the added node", ->
    addNodesTo graph
    graph.getNode('0').should.be.type 'object'
    graph.getNode('1').should.be.type 'object'
    graph.getNode('5').should.be.type 'object'
    return
  return

describe "Remove node", ->
  graph = new Graph()
  it "should return undefined if the node doesn't exist in the first place", ->
    Should.not.exist graph.removeNode(null)
    Should.not.exist graph.removeNode(2)
  it "should have kept the node size constant", ->
    graph.nodeSize.should.eql 0
  it "should return the value of node removed", ->
    addNodesTo graph
    graph.removeNode('0').should.be.type 'object'
    graph.removeNode('2').should.be.type 'object'
    graph.removeNode('5').should.be.type 'object'
  it "should have updated the node size", ->
    graph.nodeSize.should.be.exactly 3
  it "should have removed the node", ->
    Should.not.exist graph.getNode('0')
    Should.not.exist graph.getNode('2')
    Should.not.exist graph.getNode('5')

describe "Add edge", ->
  graph = new Graph()
  it "should return undefined if either/both nodes don't exist in the graph", ->
    Should.not.exist graph.addEdge('6', '7')
    Should.not.exist graph.addEdge('0', '7')
    Should.not.exist graph.addEdge('99', '0')
    addNodesTo graph
    Should.not.exist graph.addEdge('6', '7')
    Should.not.exist graph.addEdge('0', '7')
    Should.not.exist graph.addEdge('99', '0')
  it "should add the edge and return the edge object", ->
    graph.addEdge('0', '1').should.be.type 'object'
    graph.addEdge('1', '0').should.be.type 'object'
    graph.addEdge('2', '1').should.be.type 'object'
  it "should have updated the edge size", ->
    graph.edgeSize.should.be.exactly 3
  it "should have initiated the edge weight to 1", ->
    graph.addEdge('4', '1').weight.should.be.exactly 1
    graph.addEdge('4', '5').weight.should.be.exactly 1
    graph.addEdge('2', '5').weight.should.be.exactly 1
  it "should allow the node to add an edge to itself", ->
    graph.addEdge('1', '1').should.be.type 'object'
    graph.addEdge('5', '5').should.be.type 'object'
  it "should count a self-directing edge as a single one", ->
    graph.edgeSize.should.be.exactly 8
  it "should return undefined if the edge already exists", ->
    Should.not.exist graph.addEdge('0', '1')
    Should.not.exist graph.addEdge('1', '1')
    Should.not.exist graph.addEdge('1', '0')

describe "Get edge", ->
  graph = new Graph()
  it "should return undefined if the nodes aren't found", ->
    Should.not.exist graph.getEdge('0', '1')
  it "should return undefined if the edge isn't found", ->
    addNodesTo graph, yes
    Should.not.exist graph.getEdge('2', '4')
    Should.not.exist graph.getEdge('0', '1')
  it "should return the edge found", ->
    graph.getEdge('0', '3').should.be.type 'object'
    graph.getEdge('1', '0').should.be.type 'object'
    graph.getEdge('1', '2').should.be.type 'object'
    graph.getEdge('2', '1').should.be.type 'object'
    graph.getEdge('4', '0').should.be.type 'object'
    graph.getEdge('4', '1').should.be.type 'object'
    graph.getEdge('5', '2').should.be.type 'object'
    graph.getEdge('5', '5').should.be.type 'object'

describe "Remove edge", ->
  graph = new Graph()
  it "should return undefined if either node's not found", ->
    Should.not.exist graph.removeEdge(0, 1)
    Should.not.exist graph.removeEdge(undefined, undefined)
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
    graph.removeEdge('0', '3').weight.should.be.exactly 9
    graph.removeEdge('1', '0').weight.should.be.exactly 9
    graph.removeEdge('1', '2').weight.should.be.exactly 9
    graph.removeEdge('2', '1').weight.should.be.exactly 9
    graph.removeEdge('4', '0').weight.should.be.exactly 9
    graph.removeEdge('4', '1').weight.should.be.exactly 9
    graph.removeEdge('5', '2').weight.should.be.exactly 9
  it "should have kept track of the edge count", ->
    graph.edgeSize.should.be.exactly 1
  it "should remove a self-directing correctly", ->
    graph.removeEdge('5', '5').weight.should.be.exactly 9
    graph.edgeSize.should.be.exactly 0
  it "should leave an empty graph after removing all the edges", ->
    Should.not.exist graph.removeEdge('0', '3')
    Should.not.exist graph.removeEdge('1', '0')
    Should.not.exist graph.removeEdge('1', '2')
    Should.not.exist graph.removeEdge('2', '1')
    Should.not.exist graph.removeEdge('4', '0')
    Should.not.exist graph.removeEdge('4', '1')
    Should.not.exist graph.removeEdge('5', '2')
    Should.not.exist graph.removeEdge('5', '5')

describe "Get all in edges", ->
  graph = new Graph()
  it "should return empty array for a non-existant node", ->
    graph.getOutEdgesOf('5').should.eql []
    graph.getOutEdgesOf(undefined).should.eql []
  it "should return empty array for no edges", ->
    addNodesTo graph
    graph.getInEdgesOf('0').should.eql []
    graph.getInEdgesOf('1').should.eql []
    graph.getInEdgesOf('5').should.eql []
  graph2 = new Graph()
  it "should return the in edges", ->
    addNodesTo graph2, yes
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    graph2.getInEdgesOf('0').length.should.be.exactly 2
    graph2.getInEdgesOf('0').should.containEql graph2.getEdge('1', '0')
    graph2.getInEdgesOf('0').should.containEql graph2.getEdge('4', '0')

    graph2.getInEdgesOf('1').length.should.be.exactly 2
    graph2.getInEdgesOf('1').should.containEql graph2.getEdge('2', '1')
    graph2.getInEdgesOf('1').should.containEql graph2.getEdge('4', '1')

    graph2.getInEdgesOf('2').length.should.be.exactly 2
    graph2.getInEdgesOf('2').should.containEql graph2.getEdge('1', '2')
    graph2.getInEdgesOf('2').should.containEql graph2.getEdge('5', '2')

    graph2.getInEdgesOf('3').length.should.be.exactly 1
    graph2.getInEdgesOf('3').should.containEql graph2.getEdge('0', '3')

    graph2.getInEdgesOf('4').should.eql []
    graph2.getInEdgesOf('5').length.should.be.exactly 1
    graph2.getInEdgesOf('5').should.containEql graph2.getEdge('5', '5')

describe "Get all out edges", ->
  graph = new Graph()
  it "should return empty array for a non-existant node", ->
    graph.getOutEdgesOf('5').should.eql []
    graph.getOutEdgesOf(undefined).should.eql []
  it "should return empty array for no edges", ->
    addNodesTo graph
    graph.getOutEdgesOf('0').should.eql []
    graph.getOutEdgesOf('1').should.eql []
  graph2 = new Graph()
  it "should return the in edges", ->
    addNodesTo graph2, yes
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    graph2.getOutEdgesOf('0').length.should.be.exactly 1
    graph2.getOutEdgesOf('0').should.containEql graph2.getEdge('0', '3')

    graph2.getOutEdgesOf('1').length.should.be.exactly 2
    graph2.getOutEdgesOf('1').should.containEql graph2.getEdge('1', '0')
    graph2.getOutEdgesOf('1').should.containEql graph2.getEdge('1', '2')

    graph2.getOutEdgesOf('2').length.should.be.exactly 1
    graph2.getOutEdgesOf('2').should.containEql graph2.getEdge('2', '1')

    graph2.getOutEdgesOf('3').should.eql []

    graph2.getOutEdgesOf('4').length.should.be.exactly 2
    graph2.getOutEdgesOf('4').should.containEql graph2.getEdge('4', '0')
    graph2.getOutEdgesOf('4').should.containEql graph2.getEdge('4', '1')

    graph2.getOutEdgesOf('5').length.should.be.exactly 2
    graph2.getOutEdgesOf('5').should.containEql graph2.getEdge('5', '2')
    graph2.getOutEdgesOf('5').should.containEql graph2.getEdge('5', '5')

describe "Get all edges", ->
  graph = new Graph()
  it "should return an empty array if node doesn't exist", ->
    graph.getAllEdgesOf(0).should.eql []
    graph.getAllEdgesOf(undefined).should.eql []
  it "should return an empty array if the node doesn't have edges", ->
    addNodesTo graph
    graph.getAllEdgesOf('0').should.eql []
    graph.getAllEdgesOf('1').should.eql []
    graph.getAllEdgesOf('5').should.eql []
  graph2 = new Graph()
  it "should return an array of edges", ->
    addNodesTo graph2, yes
    ###
    1 <- 2 <-> 3
    |^   ^     ^
    v \  |     |
    4   \5     6 <->
    ###
    graph2.getAllEdgesOf('0').length.should.be.exactly 3
    graph2.getAllEdgesOf('0').should.containEql graph2.getEdge('0', '3')
    graph2.getAllEdgesOf('0').should.containEql graph2.getEdge('1', '0')
    graph2.getAllEdgesOf('0').should.containEql graph2.getEdge('4', '0')

    graph2.getAllEdgesOf('1').length.should.be.exactly 4
    graph2.getAllEdgesOf('1').should.containEql graph2.getEdge('1', '0')
    graph2.getAllEdgesOf('1').should.containEql graph2.getEdge('1', '2')
    graph2.getAllEdgesOf('1').should.containEql graph2.getEdge('2', '1')
    graph2.getAllEdgesOf('1').should.containEql graph2.getEdge('4', '1')

    graph2.getAllEdgesOf('2').length.should.be.exactly 3
    graph2.getAllEdgesOf('2').should.containEql graph2.getEdge('2', '1')
    graph2.getAllEdgesOf('2').should.containEql graph2.getEdge('1', '2')
    graph2.getAllEdgesOf('2').should.containEql graph2.getEdge('5', '2')

    graph2.getAllEdgesOf('3').length.should.be.exactly 1
    graph2.getAllEdgesOf('3').should.containEql graph2.getEdge('0', '3')

    graph2.getAllEdgesOf('4').length.should.be.exactly 2
    graph2.getAllEdgesOf('4').should.containEql graph2.getEdge('4', '0')
    graph2.getAllEdgesOf('4').should.containEql graph2.getEdge('4', '1')
  it "should not duplicate a self-pointing edge", ->
    graph2.getAllEdgesOf('5').length.should.be.exactly 2
    graph2.getAllEdgesOf('5').should.containEql graph2.getEdge('5', '2')
    graph2.getAllEdgesOf('5').should.containEql graph2.getEdge('5', '5')

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
    lastCallArgs[1].should.be.exactly '5'

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
    newNode = graph.addNode()._id
    graph.addEdge(newNode, newNode, 999)
    callback = sinon.spy()
    graph.forEachEdge callback
    callback.callCount.should.be.exactly 9

# TODO test getDrawableEdges
# describe "Get node array", ->
#   graph = new Graph()
#   it "should return an empty array for an empty graph", ->
#     graph.getNodeArray().should.eql []
#   it "should return a list of nodes a non-empty graph, sorted by label", ->
#     addNodesTo graph
#     nodeLables = (node.label for node in graph.getNodeArray())
#     nodeLables.should.eql [0, 1, 2, 3, 4, 5]
#   it "should be sorted by label, and not care about the internal `_id`", ->
#     graph.removeNode('3')
#     graph.addNode('8')
#     graph.addNode('7')
#     nodeLables = (node.label for node in graph.getNodeArray())
#     nodeLables.should.eql [0, 1, 2, 3, 4, 5, 6]
