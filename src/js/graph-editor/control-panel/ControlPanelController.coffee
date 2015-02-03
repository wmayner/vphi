'use strict'
###
# graph-editor/control-panel/ControlPanelController.coffee
###

graph = require '../../services/graph'
format = require '../../services/format'

module.exports =  [
  '$scope'
  graph.name
  format.name
  ($scope, graph, format) ->
    update = ->
      $scope.currentPastState = graph.pastState?.join(', ') or null
      $scope.possiblePastStates = graph.getPossiblePastStates()
      $scope.nodes = format.nodes([0...graph.nodeSize]).join(', ')

    # Intialize.
    update()

    $scope.select = (pastState) ->
      log.debug "GRAPH_CONTROLS: Setting past state to [#{pastState}]."
      graph.setPastState(pastState)

    $scope.$on 'vphiGraphUpdated', ->
      log.debug 'GRAPH_CONTROLS: Receieved graph update.'
      $scope.$apply update
]
