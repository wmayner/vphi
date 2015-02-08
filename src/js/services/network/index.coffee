'use strict'
###
# services/graph/index.coffee
###

commonUtils = require '../../utils'
# TODO provide utils in service
utils = require './utils'
Graph = require './graph'
tpmify = require './tpmify'
mechanism = require './mechanism'
examples = require './examples'

name = 'vphi.services.network'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    '$timeout'
    ($rootScope, $timeout) ->

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

      reverseEdgeKey = (key) ->
        if not key?
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
          # TODO refactor tpmify
          @tpm = tpmify this
          @currentState = []
          @pastState = @getPossiblePastStates()[0]

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

        addEdge: (sourceId, targetId) ->
          edge = @graph.addEdge(sourceId, targetId)
          @update()
          return edge

        addEdges: (nodeIdPairs) ->
          edges = []
          for pair in nodeIdPairs
            edges.push @graph.addEdge(pair[0], pair[1])
          @update()
          return edges

        removeEdge: (sourceId, targetId) ->
          removed = @graph.removeEdge(sourceId, targetId)
          @update()
          return removed

        getNodes: -> @graph.getNodes()

        getDrawableEdges: ->
          ###
          _Returns:_ An array of edges suitable for drawing on a plane. Bidirectional
          edges are merged into a single object with the `bidirectional` attribute
          set to true, and reflexive edges (self-loops) are not included.
          ###
          drawableEdges = {}
          @graph.forEachEdge (edge) ->
            # Don't add self-loops (these are recorded as attributes on the node).
            if edge.source._id is edge.target._id
              return
            # If this edge is the reverse of a previously seen edge, don't add a
            # second edge object; update the first to indicate that it's
            # bidirectional.
            reversed = reverseEdgeKey(edge.key)
            if drawableEdges[reversed]
              drawableEdges[reversed].bidirectional = true
              return
            # Store the edge object.
            drawableEdges[edge.key] = edge
          # Return an array of edges.
          return (edge for key, edge of drawableEdges)

        getNodeByIndex: (index) ->
          result = null
          @graph.forEachNode (node, id) ->
            if node.index is index
              result = node
          return result

        getNodesByIndex: ->
          return _.sortBy((node for id, node of @graph._nodes), 'index')

        mapByIndex: (operation) ->
          return (operation(node) for node in @getNodesByIndex())

        isSameLink: (key, other) ->
          return (key is other or key is reverseEdgeKey(other))

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
          return

        cycleMechanisms: (nodes) ->
          next_index = mechanism.names.indexOf(nodes[0].mechanism) + 1
          if next_index is mechanism.names.length then next_index = 0
          for node in nodes
            node.mechanism = mechanism.names[next_index]
          @update()
          return

        toggleState: (node) ->
          node.on = utils.negate(node.on)
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
            @graph.addEdge(node._id, node._id)
          else
            @graph.removeEdge(node._id, node._id)
          @update()
          return

        toggleSelfLoops: (nodes) ->
          initial = nodes[0].reflexive
          for node in nodes
            node.reflexive = not initial
            if node.reflexive
              @graph.addEdge(node._id, node._id)
            else
              @graph.removeEdge(node._id, node._id)
          @update()
          return

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
          r = (((if @graph.getEdge(i._id, j._id) then 1 else 0) \
                for j in nodes) for i in nodes)
          return r

        setPastState: (state) =>
          old = @pastState
          @pastState = state
          llog "Changed past state from [#{old}] to [#{@pastState}]."
          @update()
          return

        # TODO have special 'IN' mechanism, that doesn't restrict past state?
        _checkPossiblePastState: (pastStateIndex) ->
          # Get the probabilities for each node being on given the past state.
          row = @tpm[pastStateIndex]
          for own id, n of @_nodes
            # If the node has no inputs, it can have any past state.
            unless @graph.getInEdgesOf(id).length is 0
              # If it does have inputs, check that the TPM says there's a nonzero
              # probability of that node being on if it currently is, and a zero
              # probability if it isn't.
              if ((@currentState[n.index] > 0 and row[n.index] is 0) or
                  (@currentState[n.index] is 0 and row[n.index] > 0))
                return false
          return true

        getPossiblePastStates: ->
          numStates = Math.pow(2, @size())
          result = (commonUtils.holiIndexToState(pastStateIndex, @size()) \
            for pastStateIndex in [0...numStates] \
            when @_checkPossiblePastState(pastStateIndex))
          if result.length is 0
            return false
          return result

        updatePastState: ->
          possiblePastStates = @getPossiblePastStates()

          return if @pastState.join('') in
            (s.join('') for s in possiblePastStates)

          old = @pastState
          if not possiblePastStates
            @pastState = null
          else
            @pastState = possiblePastStates[0]
          llog "  Changed past state from [#{old}] to [#{@pastState}]."
          return

        updateCurrentState: ->
          old = @currentState
          @currentState = @getNodeProperties('on', [0...@size()])
          llog "  Changed current state from [#{old}] to [#{@currentState}]."
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
          llog "  Updated TPM."
          return

        toJSON: ->
          jsonNodes = []
          @graph.forEachNode (node, id) ->
            jsonNodes.push nodeToJSON(node)
          data =
            nodes: jsonNodes
            connectivityMatrix: @getConnectivityMatrix()
            pastState: @pastState
          console.log data
          return JSON.stringify data

        loadJSON: (json) ->
          json = JSON.parse(json)
          @graph = new Graph()
          # Add nodes.
          for node in json.nodes
            @graph.addNode(node)
          # Add edges.
          for row, i in json.connectivityMatrix
            for elt, j in row
              if elt then @addEdge(i, j)
          # Set past state.
          @pastState = json.pastState
          @update()
          return

        exampleNames: (key for own key, val of examples)

        loadExample: (exampleName) ->
          @graph = examples[exampleName]()
          @update()
          return

        update: ->
          @updateCurrentState()
          @updateTpm()
          @updatePastState()
          broadcast()
          localStorage.setItem 'network', @toJSON()
          return

      # ========================================================================

      network = new Network()
      # Load previous graph if available.
      storedNetwork = localStorage.getItem 'network'
      if storedNetwork
        network.loadJSON storedNetwork
      else
        network.loadExample network.exampleNames[0]

      return network
  ]
