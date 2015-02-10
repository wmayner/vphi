'use strict'
###
# network-editor/control-panel/ControlPanelController.coffee
###

networkService = require '../../services/network'
formatService = require '../../services/format'

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
        isJson = (
          file.name.indexOf('.json', file.name.length - '.json'.length) isnt -1
        )
        if isJson
          try
            console.log file
            r = new FileReader()
            text = r.readAsText(file)
            console.log text
            network.loadJSON JSON.parse(text)
          catch e
            log.error e
        else
          log.warn "Cannot import a network file without the '.json' extension."

    $scope.export = ->
      blob = new Blob [network.toJSON()], {type: 'application/json'}
      window.saveAs blob, 'network.json'

    $scope.examples = network.exampleNames
    $scope.load = (exampleName) -> network.loadExample(exampleName)

    $scope.select = (pastState) ->
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
    $scope.$on (networkService.name + '.updated'), ->
      log.debug 'NETWORK_CONTROLS: Receieved network update.'
      update()
    # Intialize.
    update()

]
