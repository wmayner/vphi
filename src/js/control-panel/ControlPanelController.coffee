'use strict'
###
# control-panel/ControlPanelController.coffee
###

graphService = require '../services/graph'
computeService = require '../services/compute'

module.exports = [
  '$scope'
  graphService.name
  computeService.name
  ($scope, graph, compute) ->
    btns = $('.btn-calculate')
    btnSelectedSubsystem = $('#btn-selected-subsystem')
    btnMainComplex = $('#btn-main-complex')

    method2btn =
      'mainComplex': btnMainComplex
      'bigMip': btnSelectedSubsystem

    $scope.$on (graphService.name + '.updated'), ->
      if graph.pastState and not compute.callInProgress
        btns.removeClass 'disabled'
      else
        btns.addClass 'disabled'

    btnCooldown = false

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
      return if btnCooldown or not graph.pastState
      btn = method2btn[method]
      registerClick(btn)
      compute[method](
        success(btn), always(btn)
      )

    setTimeout (-> $scope.calculate('bigMip')), 50
]
