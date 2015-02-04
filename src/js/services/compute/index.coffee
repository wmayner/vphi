'use strict'
###
# services/compute/index.coffee
###

pyphi = require './pyphi'
graph = require '../graph'

name = 'vphi.services.compute'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    graph.name
    ($rootScope, graph) ->
      return new class PhiDataService
        data: null
        calledMethod: null
        callIeProgress: false

        mainComplex: (success, always) ->
          method = 'mainComplex'
          @calledMethod = method
          @pyphiCall method, success, always

        bigMip: (success, always) ->
          method = 'bigMip'
          @calledMethod = method
          @pyphiCall method, success, always

        pyphiCall: (method, success, always) ->
          log.debug "DATA_SERVICE: Calling `#{method}`..."
          @callInProgress = true
          pyphi[method](graph, (bigMip) =>
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
          @data.currentState = graph.currentState
          @data.pastState = graph.pastState
          log.debug "DATA_SERVICE: Data:"
          log.debug @data
          phidata = @data

          # Select the subsystem that was returned
          graph.setSelectedSubsystem(@data.subsystem.node_indices)
          graph.update()

          log.debug "DATA_SERVICE: Broadcasting data update."
          $rootScope.$broadcast (name + '.updated')
          return
  ]
