###
# services/graph/graph.coffee
###

log = require 'loglevel'
utils = require '../../utils'


llog = (msg) ->
  log.debug "NETWORK: GRAPH: #{msg}"


class Graph

  constructor: ->
    @_nodes = {}
    @numNodes = 0
    @numEdges = 0
    @_newNodeId = 0

  getNewNodeId: ->
    id = @_newNodeId
    @_newNodeId++
    return id

  addNode: (nodeData = {}) ->
    ###
    _Returns:_ the node object. Feel free to attach additional custom
    properties on it for graph algorithms' needs. **Undefined if node id
    already exists**, so as to avoid accidental overrides.
    ###
    node =
      _id: @getNewNodeId()
      _outEdges: {}
      _inEdges: {}
      index: @numNodes
      label: utils.LABEL[@numNodes]
      on: 0
      mechanism: 'OR'
      reflexive: false
      selected: false
      # Threshold for '>' and '<' mechanisms.
      threshold: 2

    for key, value of nodeData
      unless key is 'neighbors'
        node[key] = value

    @numNodes++
    @_nodes[node._id] = node

    llog "Added node #{node.label}."

    if nodeData.neighbors
      for neighbor in nodeData.neighbors
        @addEdge(node._id, neighbor._id)
        @addEdge(neighbor._id, node._id)

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

  removeNode: (nodeToRemove) ->
    ###
    _Returns:_ the node object removed, or undefined if it didn't exist in the
    first place.
    ###
    if not @getNode(nodeToRemove._id)
      llog "  Node #{nodeToRemove.label} is not in the graph."
      return
    else
      llog "Removing node #{nodeToRemove.label}..."
      for own outEdgeId of nodeToRemove._outEdges
        @removeEdge nodeToRemove._id, outEdgeId
      for own inEdgeId of nodeToRemove._inEdges
        @removeEdge inEdgeId, nodeToRemove._id
      @numNodes--
      delete @_nodes[nodeToRemove._id]
    # Reassign indices/labels so they're always consecutive integers/letters.
    @forEachNode (node) ->
      if node.index > nodeToRemove.index
        node.index--
        node.label = utils.LABEL[node.index]
    llog "  Removed node #{nodeToRemove.label}."
    return nodeToRemove

  addEdge: (sourceId, targetId, weight = 1) ->
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
    fromNode = @_nodes[sourceId]
    toNode = @_nodes[targetId]
    if not fromNode or not toNode
      llog "Node(s) don't exist; can't add edge."
      return
    if @getEdge sourceId, targetId
      llog "Edge (#{fromNode.label}, #{toNode.label}) already exists."
      return
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
    @numEdges++
    llog "Added edge (#{fromNode.label}, #{toNode.label})."
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
    edgeToDelete = @getEdge sourceId, targetId
    fromNode = @_nodes[sourceId]
    toNode = @_nodes[targetId]
    if not edgeToDelete
      llog "Edge (#{fromNode.label}, #{toNode.label}) doesn't exist."
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
    @numEdges--
    llog "Removed edge (#{fromNode.label}, #{toNode.label})."
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


module.exports = Graph
