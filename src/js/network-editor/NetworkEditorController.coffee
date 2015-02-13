'use strict'
###
# network-editor/NetworkEditorController.coffee
###
#
networkService = require '../services/network'

module.exports = [
  '$scope'
  networkService.name
  ($scope, network) ->
    $scope.activeNode = network.getNode(0)
]
