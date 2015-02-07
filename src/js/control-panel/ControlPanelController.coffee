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
  ($scope, network, compute) ->
    btns = $('.btn-calculate')
    btnSelectedSubsystem = $('#btn-selected-subsystem')
    btnMainComplex = $('#btn-main-complex')

    method2btn =
      'mainComplex': btnMainComplex
      'bigMip': btnSelectedSubsystem

    # Disable buttons if the network has no possible past state or if there's
    # already a calculation in progress.
    updateButtonState = ->
      $scope.isDisabled = compute.callInProgress or
                          not network.pastState or
                          network.size() is 0
    updateButtonState()
    $scope.$on (networkService.name + '.updated'), updateButtonState

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
        # conceptSpace.display(compute.data)
        btn.button 'reset'
        finishLoading()

    always = (btn) ->
      return ->
        btn.button 'reset'
        finishLoading()

    $scope.calculate = (method) ->
      return if btnCooldown or not network.pastState
      btn = method2btn[method]
      registerClick(btn)
      compute[method](
        success(btn), always(btn)
      )
]
