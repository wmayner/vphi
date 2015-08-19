'use strict'
###
# services/compute/index.coffee
###

pyphi = require './pyphi'

networkService = require '../network'
formatterService = require '../formatter'

name = 'vphi.services.compute'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    networkService.name
    formatterService.name
    'NETWORK_SIZE_LIMIT'
    ($rootScope, network, Formatter, NETWORK_SIZE_LIMIT) ->
      isValid = (network) ->
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

      return new class ComputeService
        constructor: ->
          # Set up a formatting object that gets labels from the network that was
          # computed.
          @format = new Formatter((index) => @network.nodes[index].label)

          stored = localStorage.getItem 'compute'
          if stored
            stored = JSON.parse(stored)
            log.debug "DATA_SERVICE: Loading stored results."
            # Need a setTimeout here to do the update after Angular is set up.
            setTimeout (=>
              # Update the service.
              @network = stored.network
              @update(stored.data)
              typesetMath()
              # Force a digest cycle.
              # TODO figure out why we need this... we shouldn't and it's ugly.
              $rootScope.$apply()
            ), 0
          else
            log.debug "DATA_SERVICE: No stored results found."

        data: null
        network: null
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
            localStorage.setItem 'compute', JSON.stringify(
              data: @data
              network: @network
            )
            @callInProgress = false
            $rootScope.$apply success
            typesetMath()
          ).always(-> $rootScope.$apply always)

        update: (data) ->
          log.debug "DATA_SERVICE: Updating with data:"
          log.debug data

          @network = network.toJSON()
          @data = data
          # Record state.
          # TODO just attach these to the service.
          @data.bigMip.state = network.state

          log.debug "DATA_SERVICE: *** Broadcasting update event. ***"
          $rootScope.$broadcast (name + '.updated')
          return
  ]
