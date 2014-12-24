###
# angular.coffee
###

utils = require './utils'
colors = require './colors'
pyphi = require './pyphi'
controls = require './graph-editor/controls'
graphEditor = require './graph-editor'
RepertoireChart = require './concept-list/repertoire'

UPDATE_EVENT =

window.vphi = angular.module 'vphi', [
  'vphiDataService'
  'vphiControls'
  'vphiConceptList'
]

window.vphiDataService = angular.module 'vphiDataService', []
  .factory 'vphiDataService', [
    '$rootScope'
    ($rootScope) ->
      new class PhiData
        constructor: ->
          @graph = graphEditor.graph

        bigMip: false

        update: =>
          console.log @graph._nodes
          console.log "UPDATING>>>>>>>>>>>>>>>>"
          pyphi.bigMip @graph, (bigMip) =>
            @bigMip = bigMip
            $rootScope.$broadcast 'vphiDataUpdated'
  ]


window.vphiControls = angular.module 'vphiControls', [
  'vphiDataService'
]
  .controller 'vphiCalculateButtonCtrl', [
    '$scope'
    'vphiDataService',
    ($scope, vphiDataService) ->
      $scope.hithere = 'hitehre'
      $scope.click = ->
        console.log "CLICKED!"
        vphiDataService.update()
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
        console.log '------------updateing concept list--------------'
        $scope.concepts = vphiDataService.bigMip.unpartitioned_constellation
        $scope.numNodes = vphiDataService.bigMip.subsystem.node_indices.length

      $scope.getSmallPhi = (concept) ->
        return utils.formatPhi(concept.phi)

      $scope.getMechanism = (concept) ->
        return (utils.LABEL[n] for n in concept.mechanism).join(' ')
  ]

  .directive 'vphiConcept', ->
    link: (scope, element, attrs) ->

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

      scope.$watch (-> scope.concept[attrs.direction]), (concept) ->
        if concept
          console.log "got new concept:"
          console.log concept
          chart.load [
            ['Unpartitioned'].concat concept.repertoire
            ['Partitioned'].concat concept.partitioned_repertoire
          ]
