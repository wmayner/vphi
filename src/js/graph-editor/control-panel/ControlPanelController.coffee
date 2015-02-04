'use strict'
###
# graph-editor/control-panel/ControlPanelController.coffee
###

graphService = require '../../services/graph'
formatService = require '../../services/format'

module.exports =  [
  '$scope'
  graphService.name
  formatService.name
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

    $scope.$on (graphService.name + '.updated'), ->
      log.debug 'GRAPH_CONTROLS: Receieved graph update.'
      update()
]