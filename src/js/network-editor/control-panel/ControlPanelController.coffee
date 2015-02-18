'use strict'
###
# network-editor/control-panel/ControlPanelController.coffee
###

networkService = require '../../services/network'
formatService = require '../../services/format'
example = require '../../services/network/example'
mechanism = require '../../services/network/mechanism'

module.exports =  [
  '$scope'
  '$upload'
  networkService.name
  formatService.name
  ($scope, $upload, network, format) ->

    $scope.$watch 'files', -> $scope.importNetwork $scope.files
    $scope.importNetwork = (files) ->
      if files
        file = files[0]
        try
          r = new FileReader()
          r.onloadend = ->
            network.loadJSON r.result
          r.readAsText(file)
        catch e
          console.error e

    $scope.export = ->
      blob = new Blob [network.toJSON()], {type: 'application/json'}
      window.saveAs blob, 'network.json'

    $scope.exampleNames = example.names
    $scope.load = (exampleName) -> network.loadExample(exampleName)

    $scope.mechanismNames = mechanism.names
    $scope.mechanisms = mechanism.keys
    $scope.selectMechanism = (mechanismKey) ->
      if $scope.selectedNodes.length > 1
        for node in $scope.selectedNodes
          node.mechanism = mechanismKey
        network.update()
      else if $scope.activeNode?
        $scope.activeNode?.mechanism = mechanismKey
        network.update()

    $scope.selectPastState = (pastState) ->
      log.debug "NETWORK_CONTROLS: Setting past state to [#{pastState}]."
      network.setPastState(pastState)

    update = ->
      $scope.currentPastState = network.pastState?.join(', ') or null
      $scope.possiblePastStates = network.getPossiblePastStates()
      $scope.nodes = (
        if network.size() > 0 then format.nodes(
          [0...network.size()]).join(', ')
        else ''
      )
      log.debug "NETWORK_CONTROLS: Updated."
    $scope.$on (networkService.name + '.updated'), ->
      log.debug 'NETWORK_CONTROLS: Receieved network update.'
      update()

    # Intialize.
    update()

]
