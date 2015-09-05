'use strict'
###
# network-editor/control-panel/ControlPanelController.coffee
###

networkService = require '../../services/network'
example = require '../../services/network/example'
mechanism = require '../../services/network/mechanism'

module.exports =  [
  '$scope'
  '$upload'
  networkService.name
  ($scope, $upload, network) ->

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
          network.setMechanism(node, mechanismKey)
      else if $scope.activeNode?
        network.setMechanism($scope.activeNode, mechanismKey)

    update = ->
      $scope.nodes = (
        if network.size() > 0 then network.format.nodes(network.getNodes()).join(', ')
        else ''
      )
      log.debug "NETWORK_CONTROLS: Updated."
    $scope.$on (networkService.name + '.updated'), ->
      log.debug 'NETWORK_CONTROLS: Received network update event.'
      update()

    # Intialize.
    update()

]
