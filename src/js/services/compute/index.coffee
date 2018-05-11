'use strict'
###
# services/compute/index.coffee
###

log = require 'loglevel'
pyphiService = require './pyphi'
networkService = require '../network'
formatterService = require '../formatter'

name = 'vphi.services.compute'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    networkService.name
    formatterService.name
    pyphiService.name
    'VERSION'
    'PYPHI_VERSION'
    ($rootScope, network, Formatter, pyphi, VERSION, PYPHI_VERSION) ->

      llog = (msg) ->
        log.debug "DATA_SERVICE: #{msg}"

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
          stored = localStorage.getItem 'compute'
          if stored
            stored = JSON.parse(stored)
            # Check that stored results are compatible with this version.
            if stored.version is VERSION
              llog "Loading stored network."
              @network = stored.network
              # Need a setTimeout here to do the update after Angular is set up.
              setTimeout (=>
                if stored.data.version? and stored.data.version is PYPHI_VERSION
                  # Update the service.
                  llog "Loading stored results."
                  @update(stored.data)
                  typesetMath()
                  # Force a digest cycle.
                  # TODO figure out why we need this... we shouldn't and it's ugly.
                  $rootScope.$apply()
                else
                  llog "Incompatible PyPhi versions; not loading stored results
                    from version `#{stored.data.version}` since this expects
                    version `#{PYPHI_VERSION}`."
              ), 0
            else
              llog "Incompatible vPhi versions; not loading stored network from
                version `#{stored.version}` since this is version
                `#{VERSION}`."
          else
            llog "No stored results found."

          # Set up a formatting object that gets labels from the network that was
          # computed.
          @format = new Formatter((index) => @network.nodes[index].label)

        data: null
        network: null
        calledMethod: null
        callInProgress: false

        mainComplex: (success, always) ->
          @pyphiCall 'mainComplex', success, always

        bigMip: (success, always) ->
          @pyphiCall 'bigMip', success, always

        pyphiCall: (method, success, always) ->
          if not network.isValid()
            always()
            llog 'Invalid network.'
            return

          llog "Calling `#{method}`..."
          @calledMethod = method
          @callInProgress = true

          pyphi[method](network, ((data) =>
            @network = network.toJSON()
            @update(data)
            localStorage.setItem 'compute', JSON.stringify(
              data: @data
              network: @network
              version: VERSION
            )
            $rootScope.$apply success
            typesetMath()
          ), ((error) =>
            if 'error' of error and error.error is ''
              log.error 'Phiserver is unreachable'
              $rootScope.$broadcast (name + '.error.NoResponse')
            else
              log.error "#{error.message}: #{error.data.type}: #{error.data.message}"
              $rootScope.$broadcast (name + '.error' + '.' + error.data.type)
          )).always(=>
            @callInProgress = false
            $rootScope.$apply always
          )

        update: (data) ->
          llog "Updating with data:"
          log.debug data

          @data = data
          # Record state.
          # TODO just attach these to the service.
          @data.bigMip.state = network.state

          llog "*** Broadcasting update event. ***"
          $rootScope.$broadcast (name + '.updated')
          return
  ]
