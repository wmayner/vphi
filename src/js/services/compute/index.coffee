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

      return new class PhiDataService
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
            return
          log.debug "DATA_SERVICE: Calling `#{method}`..."
          @callInProgress = true
          pyphi[method](network, (bigMip) =>
            @update(bigMip)
            @callInProgress = false
            $rootScope.$apply success
            # Typeset the concept list after it's loaded.
            MathJax.Hub.Queue ['Typeset', MathJax.Hub, 'concept-list-module']
            MathJax.Hub.Queue ->
              # Show it after typesetting.
              $('#concept-list-module').removeClass('hidden')
              # Need this to force the charts to recalculate their width after
              # the MathJax is rendered.
              $(window).trigger('resize')
          ).always(-> $rootScope.$apply always)

        update: (bigMip) =>
          log.debug "DATA_SERVICE: Updating..."
          @data = bigMip
          # Record current and past state.
          # TODO just attach these to the service.
          @data.currentState = network.currentState
          @data.pastState = network.pastState
          log.debug "DATA_SERVICE: Got data:"
          log.debug @data
          phidata = @data

          # Select the subsystem that was returned
          network.setSelectedSubsystem(@data.subsystem.node_indices)
          network.update()

          log.debug "DATA_SERVICE: *** Broadcasting update event. ***"
          $rootScope.$broadcast (name + '.updated')
          return
  ]
