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
            network.loadJSON JSON.parse(r.result)
          r.readAsText(file)
        catch e
          log.error e

    $scope.export = ->
      blob = new Blob [network.toJSON()], {type: 'application/json'}
      window.saveAs blob, 'network.json'

    $scope.exampleNames = example.names
    $scope.load = (exampleName) -> network.loadExample(exampleName)

    # Getter/Setter function for the active node's label. We need to use this
    # with ng-model so that we can call the d3 update and network update
    # function, respectively, whenever the model changes.
    $scope.getSetLabel = (newValue) ->
      if newValue?
        $scope.activeNode?.label = newValue
        $scope.canvasUpdate()
        update()
        return newValue
      else
        return $scope.activeNode?.label

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
      log.debug 'NETWORK_CONTROLS: Received network update event.'
      update()

    # Intialize.
    update()

]
