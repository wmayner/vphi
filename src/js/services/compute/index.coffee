'use strict'
###
# services/compute/index.coffee
###

semver = require '../../../../bower_components/semver/semver.min.js'
pyphi = require './pyphi'

networkService = require '../network'
formatterService = require '../formatter'

name = 'vphi.services.compute'
module.exports = angular.module name, []
  .factory name, [
    '$rootScope'
    networkService.name
    formatterService.name
    'VERSION'
    'NETWORK_SIZE_LIMIT'
    ($rootScope, network, Formatter, VERSION, NETWORK_SIZE_LIMIT) ->

      llog = (msg) ->
        log.debug "DATA_SERVICE: #{msg}"

      isValid = (network) ->
        if network.size() > NETWORK_SIZE_LIMIT
          log.error "DATA_SERVICE: Network cannot have more than
            #{NETWORK_SIZE_LIMIT} nodes."
          return false
        if network.tpm.length < 2
          log.info "DATA_SERVICE: Network is empty; not sending request."
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
            # Check that stored results are compatible with this version.
            if semver.valid(stored.version) and
                  semver.major(stored.version) is semver.major(VERSION)
              llog "Loading stored results."
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
              llog "Incompatible versions; not loading stored results from
                v#{stored.version or 'UNDEFINED'} since this is v#{VERSION}."
          else
            llog "No stored results found."

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
            llog 'Invalid network.'
            return
          llog "Calling `#{method}`..."
          @callInProgress = true
          pyphi[method](network, ((data) =>
            @update(data)
            localStorage.setItem 'compute', JSON.stringify(
              data: @data
              network: @network
              version: VERSION
            )
            $rootScope.$apply success
            typesetMath()
          ), ((error) =>
            log.error "#{error.message}: #{error.data.type}: #{error.data.message}"
            $rootScope.$broadcast (name + '.error' + '.' + error.data.type)
          )).always(=>
            @callInProgress = false
            $rootScope.$apply always
          )

        update: (data) ->
          llog "Updating with data:"
          log.debug data

          @network = network.toJSON()
          @data = data
          # Record state.
          # TODO just attach these to the service.
          @data.bigMip.state = network.state

          llog "*** Broadcasting update event. ***"
          $rootScope.$broadcast (name + '.updated')
          return
  ]
