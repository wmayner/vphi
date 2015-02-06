'use strict'
###
# services/graph/index.coffee
###

Graph = require './graph'
examples = require './examples'

name = 'vphi.services.graph'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    '$timeout'
    ($rootScope, $timeout) ->
      # Load previous graph if available.
      storedGraph = localStorage.getItem 'graph'
      if storedGraph
        graph = new Graph()
        graph.loadJSON(storedGraph)
      else
        graph = examples.paper()

      # Inject the event broadcasting hook.
      graph.onUpdate = ->
        localStorage.setItem('graph', graph.toJSON())
        log.debug "GRAPH_SERVICE: Broadcasting graph update."
        # Since a graph update can trigger more graph updates, we need to use
        # $timeout to allow any $apply calls to finish before broadcasting
        # another change. Otherwise there may be nested $apply's, which Angular
        # doesn't allow.
        $timeout -> $rootScope.$broadcast (name + '.updated'), 0
        return

      # TODO don't expose graph; make a public api here
      return graph
  ]
