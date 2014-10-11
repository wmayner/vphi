###
Graph implemented as a modified incidence list. O(1) for every typical
operation except `removeNode()` at O(E) where E is the number of edges.

## Overview example:

```js
var graph = new Graph;
graph.addNode('A'); // => a node object. For more info, log the output or check
                    // the documentation for addNode
graph.addNode('B');
graph.addNode('C');
graph.addEdge('A', 'C'); // => an edge object
graph.addEdge('A', 'B');
graph.getEdge('B', 'A'); // => undefined. Directed edge!
graph.getEdge('A', 'B'); // => the edge object previously added
graph.getEdge('A', 'B').weight = 2 // weight is the only built-in handy property
                                   // of an edge object. Feel free to attach
                                   // other properties
graph.getInEdgesOf('B'); // => array of edge objects, in this case only one;
                         // connecting A to B
graph.getOutEdgesOf('A'); // => array of edge objects, one to B and one to C
graph.getAllEdgesOf('A'); // => all the in and out edges. Edge directed toward
                          // the node itself are only counted once
forEachNode(function(nodeObject) {
  console.log(node);
});
forEachEdge(function(edgeObject) {
  console.log(edgeObject);
});
graph.removeNode('C'); // => 'C'. The edge between A and C also removed
graph.removeEdge('A', 'B'); // => the edge object removed
```

## Properties:

- nodeSize: total number of nodes.
- edgeSize: total number of edges.
###
class Graph
  constructor: ->
    @_nodes = {}
    @nodeSize = 0
    @edgeSize = 0
    @_newNodeId = 0

  getNewNodeId: ->
    id = @_newNodeId
    @_newNodeId++
    return id

  addNode: (nodeData = {}) ->
    ###
    The `id` is a unique identifier for the node, and should **not** change
    after it's added. It will be used for adding, retrieving and deleting
    related edges too.

    **Note** that, internally, the ids are kept in an object. JavaScript's
    object hashes the id `'2'` and `2` to the same key, so please stick to a
    simple id data type such as number or string.

    _Returns:_ the node object. Feel free to attach additional custom properties
    on it for graph algorithms' needs. **Undefined if node id already exists**,
    as to avoid accidental overrides.
    ###
    node =
      _id: @getNewNodeId()
      _outEdges: {}
      _inEdges: {}
    for key, value of nodeData
      node[key] = value
    # This attribute will be set to true if the node aquires a self-loop.
    node.reflexive = false
    @nodeSize++
    @_nodes[node._id] = node
    return node

  getNode: (id) ->
    ###
    _Returns:_ the node object. Feel free to attach additional custom properties
    on it for graph algorithms' needs.
    ###
    @_nodes[id]

  removeNode: (id) ->
    ###
    _Returns:_ the node object removed, or undefined if it didn't exist in the
    first place.
    ###
    nodeToRemove = @_nodes[id]
    if not nodeToRemove then return
    else
      for own outEdgeId of nodeToRemove._outEdges
        @removeEdge id, outEdgeId
      for own inEdgeId of nodeToRemove._inEdges
        @removeEdge inEdgeId, id
      @nodeSize--
      delete @_nodes[id]
    return nodeToRemove

  getNodeState: (id) ->
    ###
    _Returns:_ the state of the given node, or undefined if the node doesn't
    exist.
    ###
    return @getNode(id).state

  setNodeState: (id, newState) ->
    ###
    _Returns:_ the state that was just set, or undefined if the node doesn't
    exist.
    exist in the first place.
    ###
    node = @getNode(id)
    if not node then return
    node.state = newState
    return node.state

  addEdge: (source, target, weight = 1) ->
    ###
    `source` and `target` are the node id specified when it was created using
    `addNode()`. `weight` is optional and defaults to 1. Ignoring it effectively
    makes this an unweighted graph. Under the hood, `weight` is just a normal
    property of the edge object.

    _Returns:_ the edge object created. Feel free to attach additional custom
    properties on it for graph algorithms' needs. **Or undefined** if the nodes
    of id `source` or `target` aren't found, or if an edge already exists between
    the two nodes.
    ###
    if @getEdge source, target then return
    sourceNode = @_nodes[source]
    targetNode = @_nodes[target]
    if not sourceNode or not targetNode then return
    edgeToAdd =
      weight: weight
      source: source
      target: target
    sourceNode._outEdges[target] = edgeToAdd
    targetNode._inEdges[source] = edgeToAdd
    # Set the node's reflexive bit to true if the edge is a self-loop.
    if source is target
      fromNode.reflexive = true
    @edgeSize++
    return edgeToAdd

  getEdge: (source, target) ->
    ###
    _Returns:_ the edge object, or undefined if the nodes of id `source` or
    `target` aren't found.
    ###
    sourceNode = @_nodes[source]
    targetNode = @_nodes[target]
    if not sourceNode or not targetNode then return
    else sourceNode._outEdges[target]

  removeEdge: (source, target) ->
    ###
    _Returns:_ the edge object removed, or undefined of edge wasn't found.
    ###
    sourceNode = @_nodes[source]
    targetNode = @_nodes[target]
    edgeToDelete = @getEdge source, target
    if not edgeToDelete then return
    delete sourceNode._outEdges[target]
    delete targetNode._inEdges[source]
    # Set the node's reflexive bit to false if the edge was a self-loop.
    if source is target
      fromNode.reflexive = false
    @edgeSize--
    return edgeToDelete

  getInEdgesOf: (nodeId) ->
    ###
    _Returns:_ an array of edge objects that are directed toward the node, or
    empty array if no such edge or node exists.
    ###
    targetNode = @_nodes[nodeId]
    inEdges = []
    for own source of targetNode?._inEdges
      inEdges.push(@getEdge source, nodeId)
    return inEdges

  getOutEdgesOf: (nodeId) ->
    ###
    _Returns:_ an array of edge objects that go out of the node, or empty array
    if no such edge or node exists.
    ###
    sourceNode = @_nodes[nodeId]
    outEdges = []
    for own target of sourceNode?._outEdges
      outEdges.push(@getEdge nodeId, target)
    return outEdges

  getAllEdgesOf: (nodeId) ->
    ###
    **Note:** not the same as concatenating `getInEdgesOf()` and
    `getOutEdgesOf()`. Some nodes might have an edge pointing toward itself.
    This method solves that duplication.

    _Returns:_ an array of edge objects linked to the node, no matter if they're
    outgoing or coming. Duplicate edge created by self-pointing nodes are
    removed. Only one copy stays. Empty array if node has no edge.
    ###
    inEdges = @getInEdgesOf nodeId
    outEdges = @getOutEdgesOf nodeId
    if inEdges.length is 0 then return outEdges
    selfEdge = @getEdge nodeId, nodeId
    for i in [0...inEdges.length]
      if inEdges[i] is selfEdge
        # Place that repleated in edge at the end and pop it.
        [inEdges[i], inEdges[inEdges.length - 1]] =
        [inEdges[inEdges.length - 1], inEdges[i]]
        inEdges.pop()
        break
    return inEdges.concat outEdges

  forEachNode: (operation) ->
    ###
    Traverse through the graph in an arbitrary manner, visiting each node once.
    Pass a function of the form `fn(nodeObject, nodeId)`.

    _Returns:_ undefined.
    ###
    for own nodeId, nodeObject of @_nodes
      operation nodeObject, nodeId
    # Manually return. This is to avoid CoffeeScript's nature of returning an
    # expression, unneeded and wastful (array) in this case.
    return

  forEachEdge: (operation) ->
    ###
    Traverse through the graph in an arbitrary manner, visiting each edge once.
    Pass a function of the form `fn(edgeObject)`.

    _Returns:_ undefined.
    ###
    for own nodeId, nodeObject of @_nodes
      for own target, edgeObject of nodeObject._outEdges
        operation edgeObject
    # Manual return, check forEachNode for reason.
    return

  getConnectivity: ->
    cm = {}
    @forEachEdge (edge) ->
      cm[edge.source] = edge.target
    return cm

  getNodes: ->
    return

module.exports = Graph
