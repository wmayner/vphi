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

tpmify = require './tpmify'
utils = require './utils'
mechanism = require './mechanism'

# Alphabet for letter labels of nodes.
ALPHABET = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K',
            'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
            'W', 'X', 'Y', 'Z']

# Helpers

getAllStates = (numNodes) ->
  return (utils.indexToState(i, numNodes) for i in [0...Math.pow(2, numNodes)])

checkPossiblePastState = (tpm, pastStateIndex, currentState) ->
  row = tpm[pastStateIndex]
  for i in [0...currentState.length]
    if ((currentState[i] > 0 and row[i] is 0) or
        (currentState[i] is 0 and row[i] isnt 0))
      return false
  return true


class Graph

  constructor: ->
    @_nodes = {}
    @nodeSize = 0
    @edgeSize = 0
    @_newNodeId = 0
    @pastState = undefined
    @currentState = undefined
    @tpm = undefined
    @controls = undefined

  # User will select a past state

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
      index: @nodeSize
      label: ALPHABET[@nodeSize]
      on: 0
      mechanism: 'MAJ'
      reflexive: false
    for key, value of nodeData
      node[key] = value
    @nodeSize++
    @_nodes[node._id] = node
    @update()
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

  getNodeByIndex: (index) ->
    result = null
    @forEachNode (node, id) ->
      if node.index is index
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
    # Reassign indices so they're always consecutive integers.
    @forEachNode (node) ->
      if node.index > nodeToRemove.index
        node.index--
    @update()
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
    @update()
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
    @update()
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

  getNodesByIndex: ->
    return (@getNodeByIndex(index) for index in [0...@nodeSize])

  mapByIndex: (operation) ->
    return (operation(node) for node in @getNodesByIndex())

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

  # Return the given property for each node, in order of node indices.
  getNodeProperties: (property, node_indices) ->
    if node_indices?
      return (node[property] for node in @getNodesByIndex() when node.index in node_indices)
    else
      return (node[property] for node in @getNodesByIndex())

  cycleMechanism: (node) ->
    next_index = mechanism.names.indexOf(node.mechanism) + 1
    if next_index is mechanism.names.length then next_index = 0
    node.mechanism = mechanism.names[next_index]
    @update()

  toggleState: (node) ->
    node.on = utils.negate(node.on)
    @update()

  toggleReflexivity: (node) ->
    node.reflexive = not node.reflexive
    if node.reflexive
      @addEdge(node._id, node._id)
    else
      @removeEdge(node._id, node._id)
    @update()

  getCurrentState: (node_indices) ->
    return @getNodeProperties('on', node_indices)

  getPastState: (node_indices) ->
    if not @pastState
      return false
    return (@pastState[i] for i in node_indices)

  # TODO test
  getConnectivityMatrix: ->
    (((if @getEdge(sourceId, targetId) then 1 else 0) \
      for targetId in [0...@nodeSize]) for sourceId in [0...@nodeSize])

  # TODO just take graph, keep a tpm in graph?
  getPossiblePastStates: ->
    numStates = Math.pow(2, @nodeSize)
    result = (utils.indexToState(pastStateIndex, @nodeSize) \
      for pastStateIndex in [0...numStates] \
      when checkPossiblePastState(@tpm, pastStateIndex, @currentState))
    if result.length is 0
      return false
    return result

  setPastState: (state) ->
    @pastState = state
    @update()

  updatePastState: ->
    possiblePastStates = @getPossiblePastStates()
    if not possiblePastStates
      @pastState = false
    else
      @pastState = possiblePastStates[0]

  updateCurrentState: ->
    @currentState = @getNodeProperties('on', [0...@nodeSize])

  updateTpm: =>
    @tpm = tpmify(this)

  update: =>
    @updateCurrentState()
    @updateTpm()
    @updatePastState()
    @controls.update(this)

module.exports = Graph
