'use strict'
###
# control-panel/ControlPanelController.coffee
###

networkService = require '../services/network'
computeService = require '../services/compute'

module.exports = [
  '$scope'
  networkService.name
  computeService.name
  'NETWORK_SIZE_LIMIT'
  ($scope, network, compute, NETWORK_SIZE_LIMIT) ->
    btns = $('.btn-calculate')
    btnSelectedSubsystem = $('#btn-selected-subsystem')
    btnMainComplex = $('#btn-main-complex')

    method2btn =
      'mainComplex': btnMainComplex
      'bigMip': btnSelectedSubsystem

    $scope.NETWORK_SIZE_LIMIT = NETWORK_SIZE_LIMIT

    update = ->
      # Display a warning if there are too many nodes
      $scope.size = network.size()
      # Disable buttons if there's already a calculation in progress, the
      # network is empty, or the network is too big.
      $scope.isDisabled = compute.callInProgress or
                          network.tpm.length < 2 or
                          network.size() >= NETWORK_SIZE_LIMIT
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
