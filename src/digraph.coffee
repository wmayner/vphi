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
    _Returns:_ the node object. Feel free to attach additional custom properties
    on it for graph algorithms' needs. **Undefined if node id already exists**,
    as to avoid accidental overrides.
    ###
    node =
      _id: @getNewNodeId()
      _outEdges: {}
      _inEdges: {}
      label: @nodeSize
    for key, value of nodeData
      node[key] = value
    # This attribute will be set to true if the node aquires a self-loop.
    node.reflexive = false
    @nodeSize++
    @_nodes[node._id] = node
    return node

  getNode: (id) ->
    ###
    _Returns:_ the node object.
    ###
    @_nodes[id]

  getNodes: ->
    ###
    _Returns:_ an array of all node objects.
    ###
    (@_nodes[id] for id in Object.keys(@_nodes))

  getNodeByLabel: (label) ->
    result = null
    @forEachNode (node, id) ->
      if node.label is label
        result = node
    return result

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
    # Reassign labels so they're always consecutive integers
    @forEachNode (node) ->
      if node.label > nodeToRemove.label
        node.label--
    return nodeToRemove

  addEdge: (sourceId, targetId, weight = 1) ->
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
    if @getEdge sourceId, targetId then return
    fromNode = @_nodes[sourceId]
    toNode = @_nodes[targetId]
    if not fromNode or not toNode then return
    edgeToAdd =
      weight: weight
      source: fromNode
      target: toNode
      key: "#{sourceId},#{targetId}"
    fromNode._outEdges[targetId] = edgeToAdd
    toNode._inEdges[sourceId] = edgeToAdd
    # Set the node's reflexive bit to true if the edge is a self-loop.
    if sourceId is targetId
      fromNode.reflexive = true
    @edgeSize++
    return edgeToAdd

  getEdge: (sourceId, targetId) ->
    ###
    _Returns:_ the edge object, or undefined if either of the nodes `source` or
    `target` aren't found.
    ###
    fromNode = @_nodes[sourceId]
    toNode = @_nodes[targetId]
    if not fromNode or not toNode then return
    else return fromNode._outEdges[targetId]

  removeEdge: (sourceId, targetId) ->
    ###
    _Returns:_ the edge object removed, or undefined of edge wasn't found.
    ###
    fromNode = @_nodes[sourceId]
    toNode = @_nodes[targetId]
    edgeToDelete = @getEdge sourceId, targetId
    if not edgeToDelete then return
    delete fromNode._outEdges[targetId]
    delete toNode._inEdges[sourceId]
    # Set the node's reflexive bit to false if the edge was a self-loop.
    if sourceId is targetId
      fromNode.reflexive = false
    # Unset the bidirectional bit of the reverse edge if it exists
    reverseEdge = @getEdge(targetId, sourceId)
    if reverseEdge
      delete reverseEdge.bidirectional
    @edgeSize--
    return edgeToDelete

  getInEdgesOf: (nodeId) ->
    ###
    _Returns:_ an array of edge objects that are directed toward the node, or
    empty array if no such edge or node exists.
    ###
    toNode = @_nodes[nodeId]
    inEdges = []
    for own sourceId of toNode?._inEdges
      inEdges.push(@getEdge sourceId, nodeId)
    return inEdges

  getOutEdgesOf: (nodeId) ->
    ###
    _Returns:_ an array of edge objects that go out of the node, or empty array
    if no such edge or node exists.
    ###
    fromNode = @_nodes[nodeId]
    outEdges = []
    for own targetId of fromNode?._outEdges
      outEdges.push(@getEdge nodeId, targetId)
    return outEdges

  getAllEdgesOf: (nodeId) ->
    ###
    **Note:** not the same as concatenating `getInEdgesOf()` and
    `getOutEdgesOf()`. Some nodes might have an edge pointing toward itself.
    This method solves that duplication.

    _Returns:_ an array of edge objects linked to the node, no matter if they're
    outgoing or coming. Duplicate edge created by self-pointing nodes are
    removed. Only one copy stays. Empty array if node has no edges.
    ###
    inEdges = @getInEdgesOf nodeId
    outEdges = @getOutEdgesOf nodeId
    if inEdges.length is 0 then return outEdges
    selfEdge = @getEdge nodeId, nodeId
    for i in [0...inEdges.length]
      if inEdges[i] is selfEdge
        # Place that repeated in edge at the end and pop it.
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

  getNodesByLabel: ->
    return (@getNodeByLabel(label) for label in [0...@nodeSize])

  mapByLabel: (operation) ->
    return (operation(node) for node in @getNodesByLabel())

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

  isSameLink: (key, other) ->
    return (key is other or key is @reverseKey(other))

  reverseKey: (key) ->
    if not key?
      return null
    ids = key.split(',')
    return ids[1] + ',' + ids[0]

  getDrawableEdges: ->
    ###
    _Returns:_ An array of edges suitable for drawing on a plane. Bidirectional
    edges are merged into a single object with the `bidirectional` attribute
    set to true, and reflexive edges (self-loops) are not included.
    ###
    drawableEdges = {}
    @forEachEdge (edge) ->
      # XXX
      # Don't add self-loops (these are recorded as attributes on the node).
      if edge.source._id is edge.target._id
        return
      # If this edge is the reverse of a previously seen edge, don't add a
      # second edge object; update the first to indicate that it's
      # bidirectional.
      reverseKey = "#{edge.target._id},#{edge.source._id}"
      if drawableEdges[reverseKey]
        drawableEdges[reverseKey].bidirectional = true
        return
      # Store the edge object.
      drawableEdges[edge.key] = edge
    # Return an array of edges.
    return (edge for key, edge of drawableEdges)

module.exports = Graph
