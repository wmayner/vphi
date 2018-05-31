'use strict'
###
# services/compute/index.coffee
###

log = require 'loglevel'
pyphiService = require './pyphi'
networkService = require '../network'
formatterService = require '../formatter'


llog = (msg) ->
  log.debug "DATA_SERVICE: #{msg}"


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
      return new class ComputeService
        constructor: ->
          @data = null
          @networkJSON = null  # representation of network that computed data
          @calledMethod = null
          @callInProgress = false
          @updateEvent = name + '.updated'

          # Try to load result from local storage
          @loadResult()

          # Set up a formatting object that gets labels from the network that was
          # computed.
          @format = new Formatter((index) => @networkJSON.nodes[index].label)

        majorComplex: (success, always) ->
          @pyphiCall 'majorComplex', success, always

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
          networkSnapshot = network.toJSON()
          pyphi[method](network, ((data) =>
            @update(data, networkSnapshot)
            @storeResult()
            $rootScope.$apply success
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

        update: (data, networkJSON) ->
          llog "Updating with data:"
          log.debug data

          @networkJSON = networkJSON
          @data = data
          # Record state.
          # TODO just attach these to the service.
          @data.bigMip.state = @networkJSON.state

          llog "*** Broadcasting update event. ***"
          $rootScope.$broadcast @updateEvent
          return

        storeResult: ->
          llog 'Storing result'
          localStorage.setItem 'compute', JSON.stringify {
            data: @data
            network: @networkJSON
            calledMethod: @calledMethod
            VERSION: VERSION
            PYPHI_VERSION: PYPHI_VERSION
          }

        loadResult: ->
          stored = localStorage.getItem 'compute'
          if stored
            stored = JSON.parse(stored)
            # Check that stored results are compatible with this version.
            if stored.VERSION is VERSION
              llog "Loading stored network."
              @networkJSON = stored.network
              # Need a setTimeout here to do the update after Angular is set up.
              setTimeout (=>
                if stored.data.version? and stored.data.version is PYPHI_VERSION
                  # Update the service.
                  llog "Loading stored results."
                  @calledMethod = stored.calledMethod
                  @update(stored.data, stored.network)
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
                version `#{stored.VERSION}` since this is version
                `#{VERSION}`."
          else
            llog "No stored results found."

        restoreNetwork: ->
          network.loadJSON @networkJSON

  ]
