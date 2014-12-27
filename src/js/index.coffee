###
# index.coffee
###

'use strict'

utils = require './utils'
colors = require './colors'
pyphi = require './pyphi'
graphEditor = require './graph-editor'
conceptSpace = require './concept-space'
RepertoireChart = require './concept-list/repertoire'


window.vphi = angular.module 'vphi', [
  'vphiDataService'
  'vphiControls'
  'vphiConceptList'
]

window.vphiDataService = angular.module 'vphiDataService', []
  .factory 'vphiDataService', [
    '$rootScope'
    ($rootScope, $scope) ->
      new class PhiData
        bigMip: false

        update: (success, always) =>
          console.log "DATA_SERVICE: Updating..."
          pyphi.bigMip(graphEditor.graph, (bigMip) =>
            @bigMip = bigMip
            console.log "DATA_SERVICE: Broadcasting data update."
            $rootScope.$broadcast 'vphiDataUpdated'
            $rootScope.$apply success
          ).always(-> $rootScope.$apply always)
  ]


window.vphiControls = angular.module 'vphiControls', [
  'vphiDataService'
]
  .controller 'vphiCalculateButtonCtrl', [
    '$scope'
    'vphiDataService',
    ($scope, vphiDataService) ->
      btnCooldown = false

      startLoading = ->
        $('#output-phi').html '···'
        $('#concept-space-loading-spinner').removeClass 'hidden'
        $('#concept-space-loading-spinner').show()
        $('#concept-space-overlay').removeClass 'hidden'
        $('#concept-space-overlay').show()

      finishLoading = ->
        $('#concept-space-loading-spinner').fadeOut 400, ->
          btnCooldown = false
        $('#concept-space-overlay').fadeOut 400

      displayBigMip = (bigMip) ->
        # Round to PRECISION.
        phi = utils.formatPhi(bigMip.phi)
        # Display the result.
        $('#output-phi').html(phi)
        # Draw the unpartitioned constellation.
        conceptSpace.display(bigMip)

      $scope.click = ->
        return if btnCooldown
        btnCooldown = true
        btn = $('#btn-calculate')
        btn.button 'loading'
        startLoading()

        success = ->
          displayBigMip(vphiDataService.bigMip)

        always = ->
          btn.button 'reset'
          finishLoading()

        vphiDataService.update(success, always)
  ]

window.vphiConceptList = angular.module 'vphiConceptList', [
  'vphiDataService'
]
  .controller 'vphiConceptListCtrl', [
    '$scope'
    'vphiDataService'
    ($scope, vphiDataService) ->
      $scope.concepts = null
      $scope.numNodes = null

      $scope.$on 'vphiDataUpdated', ->
        console.log "CONCEPT_LIST: Updating concept list..."
        console.log "CONCEPT_LIST: Old concepts:"
        console.log $scope.concepts
        $scope.concepts = vphiDataService.bigMip.unpartitioned_constellation
        $scope.numNodes = vphiDataService.bigMip.subsystem.node_indices.length
        console.log "CONCEPT_LIST: New concepts:"
        console.log $scope.concepts

      $scope.getSmallPhi = (concept) ->
        return utils.formatPhi(concept.phi)

      $scope.getMechanism = (concept) ->
        return (utils.LABEL[n] for n in concept.mechanism).join(' ')
  ]

  # .directive 'vphiConcept', ->
  #   link: (scope, element, attrs) ->

  .directive 'vphiRepertoireChart', ->
    link: (scope, element, attrs) ->
      chart = new RepertoireChart
        name: 'P'
        bindto: element[0]
        data: []
        height: 150
        colors:
          'Unpartitioned': colors[attrs.direction]
          'Partitioned': colors.repertoire.partitioned
        x:
          tick:
            # count: concept.repertoire.length
            rotate: 60
            format: (x) ->
              utils.loliIndexToState(d3.round(x, 0), scope.numNodes).join(', ')
          label: (if attrs.direction is 'cause' then 'Past State' else 'Future State')

      # scope.$watch (-> scope.concept[attrs.direction]), (concept) ->

      concept = scope.concept[attrs.direction]
      console.log "REPERTOIRE_CHART: Loading new data for concept #{scope.$index} (#{attrs.direction})."
      chart.load [
        ['Unpartitioned'].concat concept.repertoire
        ['Partitioned'].concat concept.partitioned_repertoire
      ]
