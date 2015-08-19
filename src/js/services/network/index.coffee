'use strict'
###
# services/network/index.coffee
###

formatterService = require '../formatter.coffee'

commonUtils = require '../../utils'
# TODO provide utils in service
utils = require './utils'
Graph = require './graph'
tpmify = require './tpmify'
mechanism = require './mechanism'
example = require './example'

name = 'vphi.services.network'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    '$timeout'
    formatterService.name
    ($rootScope, $timeout, Formatter) ->

      # Helpers
      # ========================================================================

      llog = (msg) ->
        log.debug "NETWORK: #{msg}"

      broadcast = ->
        llog "*** Broadcasting update event. ***"
        # Since a graph update can trigger more graph updates, we need to use
        # $timeout to allow any $apply calls to finish before broadcasting
        # another change. Otherwise there may be nested $apply's, which Angular
        # doesn't allow.
        $timeout -> $rootScope.$broadcast (name + '.updated'), 0

      getAllStates = (numNodes) ->
        (commonUtils.holiIndexToState(i, numNodes) \
         for i in [0...Math.pow(2, numNodes)])

      cycleMechanism = (node) ->
        next_index = mechanism.keys.indexOf(node.mechanism) + 1
        if next_index is mechanism.keys.length then next_index = 0
        node.mechanism = mechanism.keys[next_index]
        return

      cycleThreshold = (node, max) ->
        if node.threshold >= max
          node.threshold = 0
        else
          node.threshold++
        return

      reverseEdgeKey = (key) ->
        if not key
          return null
        ids = key.split(',')
        return ids[1] + ',' + ids[0]

      nodeToJSON = (node) ->
        # Copy node object, then delete circular references.
        jsonNode = {}
        for own key, val of node
          jsonNode[key] = val
        delete jsonNode._id
        delete jsonNode._inEdges
        delete jsonNode._outEdges
        return jsonNode


      # Public API
      # ========================================================================

      network = new class Network
        constructor: (@graph = new Graph()) ->
          # Set up a formatting object that gets labels from this network.
          @format = new Formatter((index) => @getNode(index).label)
          # TODO refactor tpmify
          @tpm = tpmify this
          @state = []

        size: -> @graph.numNodes

        addNode: (node) ->
          newNode = @graph.addNode(node)
          @update()
          return newNode

        addNodes: (nodes) ->
          newNodes = []
          for node in nodes
            newNodes.push @graph.addNode(node)
          @update()
          return newNodes

        removeNode: (node) ->
          removedNode = @graph.removeNode(node)
          @update()
          return removedNode

        removeNodes: (nodes) ->
          removedNodes = []
          for node in nodes
            removedNodes.push @graph.removeNode(node)
          @update()
          return removedNodes

        getNode: (index) ->
          result = null
          @graph.forEachNode (node, id) ->
            if node.index is index
              result = node
          return result

        getNodes: (indices) ->
          if indices
            result = []
            @graph.forEachNode (node, id) ->
              result.push node if node.index in indices
          else
            result = @graph.getNodes()
          return _.sortBy result, 'index'

        getNodeById: (id) -> @graph._nodes[id]

        addEdge: (source, target) ->
          edge = @graph.addEdge(source._id, target._id)
          @update()
          return edge

        addEdges: (nodePairs) ->
          edges = []
          for pair in nodePairs
            edges.push @addEdge(pair[0], pair[1])
          @update()
          return edges

        getEdge: (source, target) ->
          @graph.getEdge(source._id, target._id)

        removeEdge: (source, target) ->
          removed = @graph.removeEdge(source._id, target._id)
          @update()
          return removed

        getDrawableEdges: ->
          ###
          _Returns:_ An array of edges suitable for drawing on a plane.
          Bidirectional edges are merged into a single object with the
          `bidirectional` attribute set to true, and reflexive edges
          (self-loops) are not included.
          ###
          drawableEdges = {}
          @graph.forEachEdge (edge) ->
            # Don't add self-loops (these are recorded as attributes on the
            # node).
            if edge.source._id is edge.target._id
              return
            # If this edge is the reverse of a previously seen edge, don't add
            # a second edge object; update the first to indicate that it's
            # bidirectional.
            reversed = reverseEdgeKey(edge.key)
            if drawableEdges[reversed]
              drawableEdges[reversed].bidirectional = true
              return
            # Store the edge object.
            drawableEdges[edge.key] = edge
          # Return an array of edges.
          return (edge for key, edge of drawableEdges)

        isSameLink: (key, otherKey) ->
          return false if not otherKey
          return (key is otherKey or key is reverseEdgeKey(otherKey))

        cycleMechanism: (node) ->
          cycleMechanism node
          @update()
          return

        cycleMechanisms: (nodes) ->
          initial = nodes[0].mechanism
          for node in nodes
            node.mechanism = initial
            cycleMechanism node
          @update()
          return

        cycleThreshold: (node) ->
          cycleThreshold node, @size()
          @update()
          return

        cycleThresholds: (nodes) ->
          for node in nodes
            cycleThreshold node, @size()
          @update()
          return

        cycleDirection: (source, target) ->
          # Cycle through link directions:
          # Original to reversed
          if (@graph.getEdge(source._id, target._id) and
              not @graph.getEdge(target._id, source._id))
            @graph.removeEdge source._id, target._id
            @graph.addEdge target._id, source._id
          # Reversed to bidirectional
          else if (not @graph.getEdge(source._id, target._id) and
                   @graph.getEdge(target._id, source._id))
            @graph.addEdge source._id, target._id
          # Bidirectional to original
          else
            @graph.removeEdge target._id, source._id
          @update()

        toggleState: (node) ->
          node.on = utils.negate node.on
          @update()
          return

        toggleStates: (nodes) ->
          initial = nodes[0].on
          for node in nodes
            node.on = utils.negate(initial)
          @update()
          return

        toggleSelfLoop: (node) ->
          node.reflexive = not node.reflexive
          if node.reflexive
            @addEdge(node, node)
          else
            @removeEdge(node, node)
          @update()
          return

        toggleSelfLoops: (nodes) ->
          initial = nodes[0].reflexive
          for node in nodes
            node.reflexive = not initial
            if node.reflexive
              @addEdge(node, node)
            else
              @removeEdge(node, node)
          @update()
          return

        setThreshold: (node, threshold) ->
          oldThreshold = node.threshold
          node.threshold = threshold
          @update()
          return oldThreshold

        getState: -> (node.on for node in @getNodes())

        getConnectivityMatrix: ->
          nodes = @getNodes()
          r = (((if @graph.getEdge(i._id, j._id) then 1 else 0) \
                for j in nodes) for i in nodes)
          return r

        updateState: ->
          old = @state
          @state = @getState()
          llog "Updated state from [#{old}] to [#{@state}]."
          return

        getSelectedSubsystem: ->
          subsystemIndices = []
          @graph.forEachNode (node, id) ->
            if node.selected
              subsystemIndices.push node.index
          # Use whole system if no subsystem is selected.
          if subsystemIndices.length is 0
            subsystemIndices = [0...@size()]
          return subsystemIndices

        setSelectedSubsystem: (subsystemIndices) ->
          @graph.forEachNode (node, id) ->
            if node.index in subsystemIndices
              node.selected = true
            else
              node.selected = false
          return

        updateTpm: ->
          @tpm = tpmify this
          llog "Updated TPM."
          return

        toJSON: ->
          jsonNodes = []
          @graph.forEachNode (node, id) ->
            jsonNodes.push nodeToJSON(node)
          # Sort the nodes by index.
          jsonNodes = _.sortBy jsonNodes, 'index'
          data =
            nodes: jsonNodes
            tpm: @tpm
            cm: @getConnectivityMatrix()
            state: @state
          return data

        loadJSON: (json) ->
          @graph = new Graph()
          # Add nodes.
          for node in json.nodes
            @graph.addNode(node)
          # Add edges.
          for row, i in json.cm
            for elt, j in row
              if elt then @graph.addEdge(i, j)
          @tpm = json.tpm
          @cm = json.cm
          @state = json.state
          @update()
          return

        loadExample: (exampleName) ->
          ex = example[exampleName]()
          if typeof ex is 'string'
            $.getJSON ex, (data) => @loadJSON data
          else
            @graph = ex
            @update()
          return

        update: ->
          @updateState()
          @updateTpm()
          broadcast()
          localStorage.setItem 'network', JSON.stringify @toJSON()
          return

      # ========================================================================

      network = new Network()
      # Load previous graph if available.
      storedNetwork = localStorage.getItem 'network'
      if storedNetwork
        network.loadJSON JSON.parse(storedNetwork)
      else
        network.loadExample example.names[0]

      return network
  ]
