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
          text = r.readAsText(file)
          network.loadJSON JSON.parse(text)
        catch e
          console.error e

    $scope.export = ->
      blob = new Blob [network.toJSON()], {type: 'application/json'}
      window.saveAs blob, 'network.json'

    $scope.exampleNames = example.names
    $scope.load = (exampleName) -> network.loadExample(exampleName)

    $scope.selectPastState = (pastState) ->
      log.debug "NETWORK_CONTROLS: Setting past state to [#{pastState}]."
      network.setPastState(pastState)

    update = ->
      log.debug "NETWORK_CONTROLS: Updating."
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

    $scope.mechanismNames = mechanism.names
    console.log $scope.mechanismNames
    $scope.mechanisms = mechanism.keys
    $scope.selectMechanism = (mechanismKey) ->
      $scope.activeNode?.mechanism = mechanismKey
      network.update()
    # Getter/Setter functions for node labels and mechanisms. We need to use
    # these with ng-model so that we can call the d3 update and network update
    # function, respectively, whenever the model changes.
    $scope.getSetLabel = (newValue) ->
      if newValue?
        $scope.activeNode?.label = newValue
        $scope.canvasUpdate()
        update()
        return newValue
      else
        return $scope.activeNode?.label
    $scope.getSetMechanism = (newValue) ->
      if newValue?
        $scope.activeNode?.mechanism = newValue
        # Update the network (thereby updating the TPM) with the new mechanism.
        network.update()
        return newValue
      else
        return $scope.activeNode?.mechanism

    # Intialize.
    update()

]
