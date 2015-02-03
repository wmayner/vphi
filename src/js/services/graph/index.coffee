'use strict'
###
# services/graph/index.coffee
###

graphEditor = require '../../graph-editor'
examples = require '../../graph-editor/examples'

module.exports = angular.module 'vphi.services.graph', []
  .factory  'vphi.services.graph', [
    '$rootScope'
    '$timeout'
    ($rootScope, $timeout) ->
      # Load previous graph if available.
      storedGraph = localStorage.getItem 'graph'
      if storedGraph
        graphEditor.load(storedGraph)
      # Grab reference to the graph.
      graph = graphEditor.graph
      # Inject the event broadcasting hook.
      graph.onUpdate = ->
        graphEditor.update()
        localStorage.setItem('graph', graph.toJSON())
        log.debug "GRAPH_SERVICE: Broadcasting graph update."
        # Since a graph update can trigger more graph updates, we need to use
        # $timeout to allow any $apply calls to finish before broadcasting
        # another change. Otherwise there may be nested $apply's, which Angular
        # doesn't allow.
        $timeout -> $rootScope.$broadcast 'vphiGraphUpdated', 0
        return

      return graph
  ]
