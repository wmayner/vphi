'use strict'
###
# services/compute/index.coffee
###

pyphi = require './pyphi'
networkService = require '../network'

name = 'vphi.services.compute'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    networkService.name
    'NETWORK_SIZE_LIMIT'
    ($rootScope, network, NETWORK_SIZE_LIMIT) ->
      isValid = (network) ->
        if not network.pastState
          log.info "PYPHI: Current state cannot be reached by any past state; not " +
                   "sending request."
          return false
        if network.size() > NETWORK_SIZE_LIMIT
          log.error "Network cannot have more than #{NETWORK_SIZE_LIMIT} nodes."
          return false
        if network.size() is 0
          log.info "PYPHI: Network is empty; not sending request."
          return false
        return true

      typesetMath = ->
        # Typeset the concept list after it's loaded.
        MathJax.Hub.Queue ['Typeset', MathJax.Hub, 'concept-list-module']
        MathJax.Hub.Queue ->
          # Show it after typesetting.
          $('#concept-list-module').removeClass('hidden')
          # Need this to force the charts to recalculate their width after
          # the MathJax is rendered.
          $(window).trigger('resize')

      return new class PhiDataService
        constructor: ->
          storedResults = localStorage.getItem 'results'
          if storedResults
            log.debug "DATA_SERVICE: Loading stored results."
            # Need a setTimeout here to do the update after Angular is set up.
            setTimeout (=>
              # Update the service.
              @update JSON.parse(storedResults)
              typesetMath()
              # Force a digest cycle.
              # TODO figure out why we need this... we shouldn't and it's ugly.
              $rootScope.$apply()
            ), 0
          else
            log.debug "DATA_SERVICE: No stored results found."

        data: null
        calledMethod: null
        callInProgress: false

        mainComplex: (success, always) ->
          method = 'mainComplex'
          @calledMethod = method
          @pyphiCall method, success, always

        bigMip: (success, always) ->
          method = 'bigMip'
          @calledMethod = method
          @pyphiCall method, success, always

        pyphiCall: (method, success, always) ->
          if not isValid(network)
            always()
            log.debug 'DATA_SERVICE: Invalid network.'
            return
          log.debug "DATA_SERVICE: Calling `#{method}`..."
          @callInProgress = true
          pyphi[method](network, (data) =>
            @update(data)
            localStorage.setItem 'results', JSON.stringify(data)
            @callInProgress = false
            $rootScope.$apply success
            typesetMath()
          ).always(-> $rootScope.$apply always)

        update: (data) ->
          log.debug "DATA_SERVICE: Updating with data:"
          log.debug data

          @data = data
          # Record current and past state.
          # TODO just attach these to the service.
          @data.bigMip.currentState = network.currentState
          @data.bigMip.pastState = network.pastState

          log.debug "DATA_SERVICE: *** Broadcasting update event. ***"
          $rootScope.$broadcast (name + '.updated')
          return
  ]
