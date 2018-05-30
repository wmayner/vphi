'use strict'
###
# control-panel/ControlPanelController.coffee
###

networkService = require '../services/network'
computeService = require '../services/compute'


joinWithAnd = (labels) ->
  # Join an array of labels: ['A', 'B', 'C'] -> 'A, B and C'
  if labels.length == 0
    return ''

  if labels.length == 1
    return labels[0]

  return labels[...-1].join(', ') + ' and ' + labels[labels.length - 1]


module.exports = [
  '$scope'
  networkService.name
  computeService.name
  'NETWORK_SIZE_LIMIT'
  ($scope, network, compute, NETWORK_SIZE_LIMIT) ->

    $scope.NETWORK_SIZE_LIMIT = NETWORK_SIZE_LIMIT

    update = ->
      # Display a warning if there are too many nodes
      # Disable buttons if there's already a calculation in progress, the
      # network is empty, or the network is too big.
      $scope.btnsDisabled = $scope.btnClicked or not network.isValid()
      $scope.tooManyNodes = not network.validateSize()
      $scope.tooManyInputs = not network.validateNodeInputs()
      $scope.overloadedNodes = joinWithAnd(n.label for n in network.overloadedNodes())

    update()
    $scope.$on network.updateEvent, update

    $scope.btnClicked = null

    registerClick = (method) ->
      $scope.btnClicked = method
      update()  # Disable buttons

    success = ->
      $scope.subsystemStateUnreachable = false

    always = ->
      $scope.btnClicked = null
      update()

    $scope.calculate = (method) ->
      return if $scope.btnClicked
      registerClick(method)
      compute[method](success, always)

    # Handle `StateUnreachableError`
    $scope.$on (computeService.name + '.error.StateUnreachableError'), ->
      $scope.subsystemStateUnreachable = true
]
