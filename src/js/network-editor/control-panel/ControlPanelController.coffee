'use strict'
###
# network-editor/control-panel/ControlPanelController.coffee
###

networkService = require '../../services/network'
formatService = require '../../services/format'

module.exports =  [
  '$scope'
  networkService.name
  formatService.name
  ($scope, network, format) ->

    $scope.select = (pastState) ->
      log.debug "NETWORK_CONTROLS: Setting past state to [#{pastState}]."
      network.setPastState(pastState)

    $scope.export = ->
      blob = new Blob [network.toJSON()]
      window.saveAs blob, 'network.json'

    $scope.import = ->

    $scope.examples = network.exampleNames
    $scope.load = (exampleName) -> network.loadExample(exampleName)

    update = ->
      $scope.currentPastState = network.pastState?.join(', ') or null
      $scope.possiblePastStates = network.getPossiblePastStates()
      $scope.nodes = (
        if network.size() > 0 then format.nodes(
          [0...network.size()]).join(', ')
        else ''
      )

    $scope.$on (networkService.name + '.updated'), ->
      log.debug 'NETWORK_CONTROLS: Receieved network update.'
      update()

    # Intialize.
    update()

]
