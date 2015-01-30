###
# graph-editor/graph.coffee
###

utils = require '../utils'
tpmify = require './tpmify'
graphUtils = require './utils'
mechanism = require './mechanism'


# Helpers

getAllStates = (numNodes) ->
  return (utils.holiIndexToState(i, numNodes) for i in [0...Math.pow(2, numNodes)])

llog = (msg) ->
  log.debug "GRAPH: #{msg}"


class Graph

  constructor: ->
    @_nodes = {}
    @nodeSize = 0
    @edgeSize = 0
    @_newNodeId = 0
    @pastState = undefined
    @currentState = undefined
    @tpm = undefined

  getNewNodeId: ->
    id = @_newNodeId
    @_newNodeId++
    return id

  _addNode: (nodeData = {}) ->
    ###
    _Returns:_ the node object. Feel free to attach additional custom
    properties on it for graph algorithms' needs. **Undefined if node id
    already exists**, so as to avoid accidental overrides.
    ###
    node =
      _id: @getNewNodeId()
      _outEdges: {}
      _inEdges: {}
      index: @nodeSize
      label: utils.LABEL[@nodeSize]
      on: 0
      mechanism: 'OR'
      reflexive: false
      # Threshold for '>' and '<' mechanisms.
      threshold: 2
      # Marks whether this node is in the currently chosen subsystem.
      inSubsystem: false

    for key, value of nodeData
      unless key is 'neighbors'
        node[key] = value

    @nodeSize++
    @_nodes[node._id] = node

    if nodeData.neighbors
      for neighbor in nodeData.neighbors
        @_addEdge(node._id, neighbor._id)
        @_addEdge(neighbor._id, node._id)

    llog "Added node #{node._id}."
    return node

  addNode: (node) ->
    newNode = @_addNode(node)
    @update()
    return newNode

  addNodes: (nodes) ->
    newNodes = []
    for node in nodes
      newNodes.push @_addNode(node)
    @update()
    return newNodes

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

  _removeNode: (id) ->
    ###
    _Returns:_ the node object removed, or undefined if it didn't exist in the
    first place.
    ###
    nodeToRemove = @_nodes[id]
    llog "Removing node #{id}..."
    if not nodeToRemove
      llog "  Node #{id} doesn't exist."
      return
    else
      for own outEdgeId of nodeToRemove._outEdges
        @_removeEdge id, outEdgeId
      for own inEdgeId of nodeToRemove._inEdges
        @_removeEdge inEdgeId, id
      @nodeSize--
      delete @_nodes[id]
    # Reassign indices/labels so they're always consecutive integers/letters.
    @forEachNode (node) ->
      if node.index > nodeToRemove.index
        node.index--
        node.label = utils.LABEL[node.index]
    llog "  Removed node #{id}."
    return nodeToRemove

  removeNode: (id) ->
    removedNode = @_removeNode(id)
    @update()
    return removedNode

  removeNodes: (ids) ->
    removedNodes = []
    for id in ids
      removedNodes.push @_removeNode(id)
    @update()
    return removedNodes

  _addEdge: (sourceId, targetId, weight = 1) ->
    ###
    `source` and `target` are the node id specified when it was created using
    `addNode()`. `weight` is optional and defaults to 1. Ignoring it
    effectively makes this an unweighted graph. Under the hood, `weight` is
    just a normal property of the edge object.

    _Returns:_ the edge object created. Feel free to attach additional custom
    properties on it for graph algorithms' needs. **Or undefined** if the nodes
    of id `source` or `target` aren't found, or if an edge already exists
    between the two nodes.
    ###
    if @getEdge sourceId, targetId
      llog "Edge #{sourceId},#{targetId} already exists."
      return
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
    llog "Added edge #{sourceId},#{targetId}."
    return edgeToAdd

  addEdge: (sourceId, targetId, weight = 1) ->
    @_addEdge(sourceId, targetId, weight = 1)
    @update()

  getEdge: (sourceId, targetId) ->
    ###
    _Returns:_ the edge object, or undefined if either of the nodes `source` or
    `target` aren't found.
    ###
    fromNode = @_nodes[sourceId]
    toNode = @_nodes[targetId]
    if not fromNode or not toNode then return
    else return fromNode._outEdges[targetId]

  _removeEdge: (sourceId, targetId) ->
    ###
    _Returns:_ the edge object removed, or undefined of edge wasn't found.
    ###
    llog "Removed edge #{sourceId},#{targetId}..."
    fromNode = @_nodes[sourceId]
    toNode = @_nodes[targetId]
    edgeToDelete = @getEdge sourceId, targetId
    if not edgeToDelete
      llog "  Edge #{sourceId},#{targetId} doesn't exist."
      return
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
    llog "  Removed edge #{sourceId},#{targetId}."
    return edgeToDelete

  removeEdge: (sourceId, targetId) ->
    @_removeEdge(sourceId, targetId)
    @update()

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

    _Returns:_ an array of edge objects linked to the node, no matter if
    they're outgoing or coming. Duplicate edge created by self-pointing nodes
    are removed. Only one copy stays. Empty array if node has no edges.
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
    return _.sortBy((node for id, node of @_nodes), 'index')

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

  cycleMechanisms: (nodes) ->
    next_index = mechanism.names.indexOf(nodes[0].mechanism) + 1
    if next_index is mechanism.names.length then next_index = 0
    for node in nodes
      node.mechanism = mechanism.names[next_index]
    @update()

  toggleState: (node) ->
    node.on = graphUtils.negate(node.on)
    @update()

  toggleStates: (nodes) ->
    initial = nodes[0].on
    for node in nodes
      node.on = graphUtils.negate(initial)
    @update()

  toggleSelfLoop: (node) ->
    node.reflexive = not node.reflexive
    if node.reflexive
      @_addEdge(node._id, node._id)
    else
      @_removeEdge(node._id, node._id)
    @update()

  toggleSelfLoops: (nodes) ->
    initial = nodes[0].reflexive
    for node in nodes
      node.reflexive = not initial
      if node.reflexive
        @_addEdge(node._id, node._id)
      else
        @_removeEdge(node._id, node._id)
    @update()

  setThreshold: (node, threshold) ->
    oldThreshold = node.threshold
    node.threshold = threshold
    @update()
    return oldThreshold

  getCurrentState: (node_indices) ->
    return @getNodeProperties('on', node_indices)

  getPastState: (node_indices) ->
    if not @pastState
      return null
    return (@pastState[i] for i in node_indices)

  getConnectivityMatrix: ->
    nodes = @getNodesByIndex()
    r = (((if @getEdge(i._id, j._id) then 1 else 0) \
            for j in nodes) for i in nodes)
    return r

  # TODO have special 'IN' mechanism, that doesn't restrict past state?
  checkPossiblePastState: (pastStateIndex) ->
    # Get the probabilities for each node being on given the past state.
    row = @tpm[pastStateIndex]
    for own id, n of @_nodes
      # If the node has no inputs, it can have any past state.
      unless @getInEdgesOf(id).length is 0
        # If it does have inputs, check that the TPM says there's a nonzero
        # probability of that node being on if it currently is, and a zero
        # probability if it isn't.
        if ((@currentState[n.index] > 0 and row[n.index] is 0) or
            (@currentState[n.index] is 0 and row[n.index] > 0))
          return false
    return true

  getPossiblePastStates: ->
    numStates = Math.pow(2, @nodeSize)
    result = (utils.holiIndexToState(pastStateIndex, @nodeSize) \
      for pastStateIndex in [0...numStates] \
      when @checkPossiblePastState(pastStateIndex))
    if result.length is 0
      return false
    return result

  setPastState: (state) =>
    old = @pastState
    @pastState = state
    @updateTpm()
    @onUpdate(this)
    llog "Changed past state from [#{old}] to [#{@pastState}]."

  updatePastState: ->
    old = @pastState
    possiblePastStates = @getPossiblePastStates()
    if not possiblePastStates
      @pastState = null
    else
      @pastState = possiblePastStates[0]
    llog "  Changed past state from [#{old}] to [#{@pastState}]."

  updateCurrentState: ->
    old = @currentState
    @currentState = @getNodeProperties('on', [0...@nodeSize])
    llog "  Changed current state from [#{old}] to [#{@currentState}]."

  getSelectedSubsystem: ->
    subsystemIndices = []
    @forEachNode (node, id) ->
      if node.selected
        subsystemIndices.push node.index
    # Use whole system if no subsystem is selected.
    if subsystemIndices.length is 0
      subsystemIndices = [0...@nodeSize]
    return subsystemIndices

  setSelectedSubsystem: (subsystemIndices) ->
    @forEachNode (node, id) ->
      if node.index in subsystemIndices
        node.selected = true
      else
        node.selected = false

  updateTpm: =>
    @tpm = tpmify(this)
    llog "  Updated TPM."

  # This is a hook to be injected by a consuming service.
  onUpdate: ->

  update: =>
    llog "Updating..."
    @updateCurrentState()
    @updateTpm()
    @updatePastState()
    @onUpdate()


module.exports = Graph
