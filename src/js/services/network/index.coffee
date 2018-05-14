'use strict'
###
# services/network/index.coffee
###

log = require 'loglevel'
semver = require 'semver'

formatterService = require '../formatter.coffee'

commonUtils = require '../../utils'
# TODO provide utils in service
utils = require './utils'
Graph = require './graph'
mechanism = require './mechanism'
example = require './example'

name = 'vphi.services.network'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    '$timeout'
    formatterService.name
    'VERSION'
    'NETWORK_SIZE_LIMIT'
    ($rootScope, $timeout, Formatter, VERSION, NETWORK_SIZE_LIMIT) ->

      # Helpers
      # ========================================================================

      llog = (msg) ->
        log.debug "NETWORK_SERVICE: #{msg}"

      broadcast = ->
        llog "*** Broadcasting update event. ***"
        # Since a graph update can trigger more graph updates, we need to use
        # $timeout to allow any $apply calls to finish before broadcasting
        # another change. Otherwise there may be nested $apply's, which Angular
        # doesn't allow.
        $timeout -> $rootScope.$broadcast (name + '.updated'), 0

      cycleMechanism = (node) ->
        nextIndex = mechanism.keys.indexOf(node.mechanism) + 1
        if nextIndex is mechanism.keys.length then nextIndex = 0
        node.mechanism = mechanism.keys[nextIndex]
        return

      cycleThreshold = (node, max) ->
        if node.threshold >= max
          node.threshold = 0
        else
          node.threshold++
        return

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

      class Network
        constructor: (@graph = new Graph()) ->
          # Set up a formatting object that gets labels from this network.
          @format = new Formatter((index) => @getNode(index).label)
          @tpm = @graph.tpmify()
          @state = []

        size: -> @graph.numNodes

        isValid: ->
          if not @validateSize()
            log.error "Network cannot have more than #{NETWORK_SIZE_LIMIT}
              nodes."
            return false

          if @size() == 0
            log.error "Network is empty"
            return false

          if not @validateNodeInputs()
            log.error("Too many inputs: ", n.label for n in @overloadedNodes())
            return false

          return true

        validateNodeInputs: ->
          # Check that all copy gates have at most one input
          return @overloadedNodes().length == 0

        overloadedNodes: ->
          # Return an array of all COPY and NOT gates with too many inputs
          overloaded = []

          @graph.forEachNode (node, id) =>
            if node.mechanism in mechanism.singleInput and
                @graph.getInEdgesOf(id).length > 1
              overloaded.push(node)

          return overloaded

        validateSize: ->
          return @size() <= NETWORK_SIZE_LIMIT

        addNode: (node) ->
          newNode = @graph.addNode(node)
          @updateAll()
          return newNode

        addNodes: (nodes) ->
          newNodes = []
          for node in nodes
            newNodes.push @graph.addNode(node)
          @updateAll()
          return newNodes

        removeNode: (node) ->
          removedNode = @graph.removeNode(node)
          @updateAll()
          return removedNode

        removeNodes: (nodes) ->
          removedNodes = []
          for node in nodes
            removedNodes.push @graph.removeNode(node)
          @updateAll()
          return removedNodes

        getNode: (index) ->
          result = null
          @graph.forEachNode (node, id) ->
            if node.index is index
              result = node
          return result

        getNodes: (indices) ->
          return @graph.getNodesByIndices indices

        getNodeById: (id) -> @graph._nodes[id]

        addEdge: (source, target) ->
          edge = @graph.addEdge(source._id, target._id)
          @updateAll()
          return edge

        addEdges: (nodePairs) ->
          edges = []
          for pair in nodePairs
            edges.push @addEdge(pair[0], pair[1])
          @updateAll()
          return edges

        getEdge: (source, target) ->
          @graph.getEdge(source._id, target._id)

        removeEdge: (source, target) ->
          removed = @graph.removeEdge(source._id, target._id)
          @updateAll()
          return removed

        getDrawableEdges: ->
          return @graph.getDrawableEdges()

        isSameLink: (key, otherKey) ->
          return false if not otherKey
          return (key is otherKey or key is @graph.reverseEdgeKey(otherKey))

        setMechanism: (node, mechanism) ->
          node.mechanism = mechanism
          @updateTPM()

        cycleMechanism: (node) ->
          cycleMechanism node
          @updateTPM()
          return

        cycleMechanisms: (nodes) ->
          initial = nodes[0].mechanism
          for node in nodes
            node.mechanism = initial
            cycleMechanism node
          @updateTPM()
          return

        cycleThreshold: (node) ->
          cycleThreshold node, @size()
          @updateTPM()
          return

        cycleThresholds: (nodes) ->
          for node in nodes
            cycleThreshold node, @size()
          @updateTPM()
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
          @updateAll()

        toggleState: (node) ->
          node.on = utils.negate node.on
          @updateState()
          return

        toggleStates: (nodes) ->
          initial = nodes[0].on
          for node in nodes
            node.on = utils.negate(initial)
          @updateState()
          return

        toggleSelfLoop: (node) ->
          node.reflexive = not node.reflexive
          if node.reflexive
            @addEdge(node, node)
          else
            @removeEdge(node, node)
          @updateAll()
          return

        toggleSelfLoops: (nodes) ->
          initial = nodes[0].reflexive
          for node in nodes
            node.reflexive = not initial
            if node.reflexive
              @addEdge(node, node)
            else
              @removeEdge(node, node)
          @updateAll()
          return

        setThreshold: (node, threshold) ->
          oldThreshold = node.threshold
          node.threshold = threshold
          @updateTPM()
          return oldThreshold

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

        getState: -> (node.on for node in @getNodes())

        _updateState: ->
          old = @state
          @state = @getState()
          llog "Updated state from [#{old}] to [#{@state}]."

        updateState: ->
          @_updateState()
          @broadcastUpdate()
          return

        _updateTPM: ->
          @tpm = @graph.tpmify()
          llog "Updated TPM."

        updateTPM: ->
          @_updateTPM()
          @broadcastUpdate()

        _updateCM: ->
          nodes = @getNodes()
          @cm = (
            ((if @graph.getEdge(i._id, j._id) then 1 else 0) \
              for j in nodes) for i in nodes)
          llog "Updated connectivity matrix."

        updateCM: ->
          @_updateCM()
          @broadcastUpdate()

        toJSON: ->
          jsonNodes = []
          @graph.forEachNode (node, id) ->
            jsonNodes.push nodeToJSON(node)
          # Sort the nodes by index.
          jsonNodes = _.sortBy jsonNodes, 'index'
          data =
            labels: (n.label for n in jsonNodes)
            nodes: jsonNodes
            tpm: @tpm
            cm: @cm
            state: @state
            version: VERSION
          return data

        loadJSON: (json) ->
          # Check that stored network is compatible with this version.
          unless semver.valid(json.version) and
                 semver.major(json.version) is semver.major(VERSION)
            llog "Incompatible versions; not loading stored network from
              v#{json.version or 'UNDEFINED'} since this is v#{VERSION}."
            return
          if not 'tpm' of json
            log.error 'Imported network must have a `tpm` attribute.'
            return
          if not 'state' of json
            log.error 'Imported network must have a `state` attribute.'
            return
          numNodes = json.state.length
          nodeIndices = [0...numNodes]
          # Make a new, empty graph.
          @graph = new Graph()
          # Load nodes if there are any, otherwise make blank ones.
          if 'nodes' of json
            for node in json.nodes
              @graph.addNode(node)
          else
            for i in json.cm
              node = @graph.addNode({mechanism: '—'})
          # Add edges if there's a connectivity matrix, otherwise assume full
          # connectivity.
          if 'cm' of json
            @cm = json.cm
          else
            @cm = ((1 for i in nodeIndices) for j in nodeIndices)
          for row, i in json.cm
            for elt, j in row
              if elt then @graph.addEdge(i, j)
          # Load TPM and state.
          @tpm = json.tpm
          @state = json.state
          llog 'Loaded network.'
          @broadcastUpdate()

        loadExample: (exampleName) ->
          ex = example[exampleName]()
          if typeof ex is 'string'
            $.getJSON ex, (data) => @loadJSON data
          else
            @graph = ex
            @updateAll()
          return

        updateAll: ->
          @_updateState()
          @_updateTPM()
          @_updateCM()
          @broadcastUpdate()

        broadcastUpdate: ->
          broadcast()
          # Save the network to localStorage.
          localStorage.setItem 'network', JSON.stringify @toJSON()
          return

      # ========================================================================

      network = new Network()
      # Load previous network if available; default to the first example.
      storedNetwork = localStorage.getItem 'network'
      if storedNetwork
        network.loadJSON JSON.parse(storedNetwork)
      else
        llog "No stored network found."
        network.loadExample example.names[0]

      return network
  ]
