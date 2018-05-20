'use strict'
###
# network-editor/control-panel/ControlPanelController.coffee
###

log = require 'loglevel'
networkService = require '../../services/network'
example = require '../../services/network/example'
mechanism = require '../../services/network/mechanism'

module.exports =  [
  '$scope'
  '$upload'
  networkService.name
  ($scope, $upload, network) ->

    $ctrl = this

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
    $scope.$watch 'networkFiles', -> $scope.importNetwork $scope.networkFiles

    $scope.export = ->
      blob = new Blob [JSON.stringify network.toJSON()], {
        type: 'application/json'
      }
      window.saveAs blob, 'network.json'

    $scope.exampleNames = example.names
    $scope.load = (exampleName) -> network.loadExample(exampleName)

    # Update d3 and network when label changes
    $ctrl.notifyUpdateLabel = ->
      log.debug "NETWORK_CONTROLS: Updated labels"
      $ctrl.onUpdateLabel()

    $scope.mechanismNames = mechanism.names
    $scope.mechanisms = mechanism.keys
    $scope.selectMechanism = (mechanismKey) ->
      if $ctrl.selectedNodes.length > 1
        for node in $ctrl.selectedNodes
          network.setMechanism(node, mechanismKey)
      else if $ctrl.activeNode?
        network.setMechanism($ctrl.activeNode, mechanismKey)

    return
]
