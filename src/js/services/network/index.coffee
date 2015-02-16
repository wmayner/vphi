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
example = require './example'

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

        getNode: (index) ->
          result = null
          @graph.forEachNode (node, id) ->
            if node.index is index
              result = node
          return result

        getNodes: ->
          return _.sortBy @graph.getNodes(), 'index'

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

        getCurrentState: -> (node.on for node in @getNodes())

        getPastState: (node_indices) ->
          if not @pastState
            return null
          return (@pastState[i] for i in node_indices)

        getConnectivityMatrix: ->
          nodes = @getNodes()
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
          for own id, n of @graph._nodes
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

          # If there are no possible past states, set to null.
          if not possiblePastStates
            @pastState = null
          else
            # Return if the current past state is possible.
            return if (@pastState and @pastState.join('') in
              (s.join('') for s in possiblePastStates))
            # Otherwise, set to the first possible one.
            old = @pastState
            @pastState = possiblePastStates[0]
            llog "Changed past state from [#{old}] to [#{@pastState}]."
          return

        updateCurrentState: ->
          old = @currentState
          @currentState = @getCurrentState()
          llog "Changed current state from [#{old}] to [#{@currentState}]."
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
          data =
            nodes: jsonNodes
            tpm: @tpm
            connectivityMatrix: @getConnectivityMatrix()
            pastState: @pastState
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
              if elt then @graph.addEdge(i, j)
          # Set past state.
          @pastState = json.pastState
          @update()
          return

        loadExample: (exampleName) ->
          @graph = example[exampleName]()
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
        network.loadExample example.names[0]

      return network
  ]
