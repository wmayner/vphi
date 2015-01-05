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
  'vphiOutputSummary'
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
            console.log "DATA_SERVICE: bigMip:"
            console.log bigMip
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

window.vphiOutputSummary = angular.module 'vphiOutputSummary', []
  .controller 'vphiOutputSummaryCtrl', [
    '$scope'
    'vphiDataService'
    ($scope, vphiDataService) ->
      $scope.bigPhi = null
      $scope.numConcepts = null

      $scope.$on 'vphiDataUpdated', ->
        d = vphiDataService.bigMip
        $scope.bigPhi = utils.formatPhi d.phi
        $scope.numConcepts = d.unpartitioned_constellation.length
        if d.unpartitioned_constellation.length > 0
          $scope.sumSmallPhi = utils.formatPhi (c.phi for c in d.unpartitioned_constellation).reduce((x, y) -> x + y)
        else
          $scope.sumSmallPhi = 0
        $scope.minimalCut = utils.formatCut d.cut_subsystem.cut
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
        $scope.concepts = vphiDataService.bigMip.unpartitioned_constellation
        $scope.numNodes = vphiDataService.bigMip.subsystem.node_indices.length
        console.log "CONCEPT_LIST: Updated concept list."

      $scope.getSmallPhi = (concept) ->
        return utils.formatPhi concept.phi

      $scope.getMechanism = (concept) ->
        return utils.formatNodes concept.mechanism
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
