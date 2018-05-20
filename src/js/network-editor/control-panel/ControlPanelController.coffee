'use strict'
###
# network-editor/control-panel/ControlPanelController.coffee
###

log = require 'loglevel'
networkService = require '../../services/network'
example = require '../../services/network/example'
mechanism = require '../../services/network/mechanism'

module.exports =  [
  networkService.name
  (network) ->
    $ctrl = this

    $ctrl.importNetwork =  ->
      if $ctrl.networkFiles
        file = $ctrl.networkFiles[0]
        try
          r = new FileReader()
          r.onloadend = ->
            network.loadJSON JSON.parse(r.result)
          r.readAsText(file)
        catch e
          log.error e

    $ctrl.exportNetwork = ->
      blob = new Blob [JSON.stringify network.toJSON()], {
        type: 'application/json'
      }
      window.saveAs blob, 'network.json'

    $ctrl.exampleNames = example.names
    $ctrl.loadExample = (exampleName) -> network.loadExample(exampleName)

    # Update d3 and network when label changes
    $ctrl.notifyUpdateLabel = ->
      log.debug "NETWORK_CONTROLS: Updated labels"
      $ctrl.onUpdateLabel()

    $ctrl.mechanismNames = mechanism.names
    $ctrl.selectMechanism = (mechanismKey) ->
      if $ctrl.selectedNodes.length > 1
        for node in $ctrl.selectedNodes
          network.setMechanism(node, mechanismKey)
      else if $ctrl.activeNode?
        network.setMechanism($ctrl.activeNode, mechanismKey)

    return
]
