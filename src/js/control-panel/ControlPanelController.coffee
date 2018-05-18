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
    btns = $('.btn-calculate')
    btnSelectedSubsystem = $('#btn-selected-subsystem')
    btnMajorComplex = $('#btn-major-complex')

    method2btn =
      'majorComplex': btnMajorComplex
      'bigMip': btnSelectedSubsystem

    $scope.NETWORK_SIZE_LIMIT = NETWORK_SIZE_LIMIT

    update = ->
      # Display a warning if there are too many nodes
      # Disable buttons if there's already a calculation in progress, the
      # network is empty, or the network is too big.
      $scope.isDisabled = compute.callInProgress or not network.isValid()

      $scope.tooManyNodes = not network.validateSize()
      $scope.tooManyInputs = not network.validateNodeInputs()
      $scope.overloadedNodes = joinWithAnd(n.label for n in network.overloadedNodes())

    update()
    $scope.$on (networkService.name + '.updated'), update

    btnCooldown = false

    # TODO use directives to manupulate the DOM
    startLoading = ->
      $('#concept-space-loading-spinner').removeClass 'hidden'
      $('#concept-space-loading-spinner').show()
      $('#concept-space-overlay').removeClass 'hidden'
      $('#concept-space-overlay').show()
      btns.addClass('disabled')

    finishLoading = ->
      $('#concept-space-loading-spinner').fadeOut 400, ->
        btnCooldown = false
      $('#concept-space-overlay').fadeOut 400
      btns.removeClass('disabled')

    registerClick = (btn) ->
      btnCooldown = true
      btn.button 'loading'
      startLoading()

    success = (btn) ->
      return ->
        btn.button 'reset'
        $scope.subsystemStateUnreachable = false
        finishLoading()

    always = (btn) ->
      return ->
        btn.button 'reset'
        finishLoading()

    $scope.calculate = (method) ->
      return if btnCooldown
      btn = method2btn[method]
      registerClick(btn)
      compute[method](
        success(btn), always(btn)
      )

    # Handle `StateUnreachableError`
    $scope.$on (computeService.name + '.error.StateUnreachableError'), ->
      $scope.subsystemStateUnreachable = true
]
