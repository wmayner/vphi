###
# index.coffee
###

'use strict'

utils = require './utils'
format = require './format'
colors = require './colors'
pyphi = require './pyphi'
graphEditor = require './graph-editor'
conceptSpace = require './concept-space'
RepertoireChart = require './concept-list/repertoire'


window.vphi = angular.module 'vphi', [
  'vphiDataService'
  'vphiMainControls'
  'vphiOutputSummary'
  'vphiConceptList'
]


window.vphiDataService = angular.module 'vphiDataService', []
  .factory 'vphiDataService', [
    '$rootScope'
    ($rootScope, $scope) ->
      # TODO handle 0 and 1-node selection as special-cases?
      new class PhiDataService
        data: null
        calledMethod: null

        getMainComplex: (success, always) ->
          method = 'mainComplex'
          @calledMethod = method
          @pyphiCall method, success, always

        getBigMip: (success, always) ->
          method = 'bigMip'
          @calledMethod = method
          @pyphiCall method, success, always

        pyphiCall: (method, success, always) ->
          log.debug "DATA_SERVICE: Calling `#{method}`..."
          pyphi[method](graphEditor.graph, (bigMip) =>
            @update(bigMip)
            $rootScope.$apply success
          ).always(-> $rootScope.$apply always)

        update: (bigMip) =>
          log.debug "DATA_SERVICE: Updating..."
          @data = bigMip
          # Record current and past state.
          # TODO just attach these to the service.
          @data.currentState = graphEditor.graph.currentState
          @data.pastState = graphEditor.graph.pastState
          log.debug "DATA_SERVICE: Data:"
          log.debug @data
          window.phidata = @data
          log.debug "DATA_SERVICE: Broadcasting data update."
          $rootScope.$broadcast 'vphiDataUpdated'
  ]


window.vphiControls = angular.module 'vphiMainControls', [
  'vphiDataService'
]
  .controller 'vphiMainCtrl', [
    '$scope'
    'vphiDataService',
    ($scope, vphiDataService) ->
      btnSelectedSubsystem = $('#btn-selected-subsystem')
      btnMainComplex = $('#btn-main-complex')

      btnCooldown = false

      startLoading = ->
        $('#concept-space-loading-spinner').removeClass 'hidden'
        $('#concept-space-loading-spinner').show()
        $('#concept-space-overlay').removeClass 'hidden'
        $('#concept-space-overlay').show()

      finishLoading = ->
        $('#concept-space-loading-spinner').fadeOut 400, ->
          btnCooldown = false
        $('#concept-space-overlay').fadeOut 400

      registerClick = (btn) ->
        btnCooldown = true
        btn.button 'loading'
        startLoading()

      success = (btn) ->
        return ->
          conceptSpace.display(vphiDataService.data)
          btn.button 'reset'
          finishLoading()

      always = (btn) ->
        return ->
          btn.button 'reset'
          finishLoading()

      $scope.clickSelectedSubsystem = ->
        return if btnCooldown or not graphEditor.graph.getPossiblePastStates()
        registerClick(btnSelectedSubsystem)
        vphiDataService.getBigMip(
          success(btnSelectedSubsystem), always(btnSelectedSubsystem)
        )

      $scope.clickMainComplex = ->
        return if btnCooldown or not graphEditor.graph.getPossiblePastStates()
        registerClick(btnMainComplex)
        vphiDataService.getMainComplex(
          success(btnMainComplex), always(btnMainComplex)
        )
  ]


window.vphiOutputSummary = angular.module 'vphiOutputSummary', []
  .controller 'vphiOutputSummaryCtrl', [
    '$scope'
    'vphiDataService'
    ($scope, vphiDataService) ->
      $scope.format = format

      $scope.currentState = null
      $scope.title = 'Subsystem'
      $scope.nodes = []
      $scope.cut = '–'
      $scope.bigPhi = '–'
      $scope.numConcepts = '–'
      $scope.sumSmallPhi = '–'

      $scope.$on 'vphiDataUpdated', ->
        d = vphiDataService.data

        if vphiDataService.calledMethod is 'mainComplex'
          $scope.title = 'Main Complex'
        else
          $scope.title = 'Subsystem'


        $scope.currentState = d.currentState
        $scope.nodes = d.subsystem.node_indices
        $scope.bigPhi = format.phi d.phi
        $scope.numConcepts = d.unpartitioned_constellation.length

        if d.unpartitioned_constellation.length > 0
          $scope.sumSmallPhi = format.phi (c.phi for c in d.unpartitioned_constellation).reduce((x, y) -> x + y)
        else
          $scope.sumSmallPhi = 0

        $scope.cut =
          intact: format.nodes d.cut_subsystem.cut.intact
          severed: format.nodes d.cut_subsystem.cut.severed
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
      $scope.currentState = null

      $scope.$on 'vphiDataUpdated', ->
        $scope.concepts = vphiDataService.data.unpartitioned_constellation
        $scope.numNodes = vphiDataService.data.subsystem.node_indices.length
        $scope.currentState = vphiDataService.data.currentState

        # Merge all unpartitioned and partitione repertoires and find the max.
        allRepertoires = (
          c.cause.repertoire
            .concat(c.cause.partitioned_repertoire)
            .concat(c.effect.repertoire)
            .concat(c.effect.partitioned_repertoire) for c in $scope.concepts
        )
        allProbabilities = [].concat.apply([], allRepertoires)
        $scope.maxProbability = _.max(allProbabilities)

        log.debug "CONCEPT_LIST: Updated concept list."
  ]

  .controller 'vphiConceptCtrl', [
    '$scope'
    ($scope) ->
      concept = $scope.concept

      $scope.format = format

      $scope.mechanism = concept.mechanism
      $scope.smallPhi = format.phi concept.phi
      $scope.smallPhiPast = format.phi concept.phi
      $scope.smallPhiPast = format.phi concept.cause.mip.phi
      $scope.smallPhiFuture = format.phi concept.effect.mip.phi


      if concept.cause.mip.phi > concept.effect.mip.phi
        $scope.smallPhiPastClass = "bold"
      else
        $scope.smallPhiFutureClass = "bold"

      $scope.causeMip = "\\frac{" +
        format.latexNodes(concept.effect.mip.mechanism) + "^{c}" +
        "}{" +
        format.latexNodes(concept.effect.mip.purview) + "^{p}" +
        "}"
      $scope.partitionedCauseMip = "\\frac{" +
        format.latexNodes(concept.cause.mip.partition[0].mechanism) + "^{c}" +
        "}{" +
        format.latexNodes(concept.cause.mip.partition[0].purview) + "^{p}" +
        "} \\times \\frac{" +
        format.latexNodes(concept.cause.mip.partition[1].mechanism) + "^{c}" +
        "}{" +
        format.latexNodes(concept.cause.mip.partition[1].purview) + "^{p}" +
        "}"
      $scope.effectMip = "\\frac{" +
        format.latexNodes(concept.effect.mip.mechanism) + "^{c}" +
        "}{" +
        format.latexNodes(concept.effect.mip.purview) + "^{f}" +
        "}"
      $scope.partitionedEffectMip = "\\frac{" +
        format.latexNodes(concept.effect.mip.partition[0].mechanism) + "^{c}" +
        "}{" +
        format.latexNodes(concept.effect.mip.partition[0].purview) + "^{f}" +
        "} \\times \\frac{" +
        format.latexNodes(concept.effect.mip.partition[1].mechanism) + "^{c}" +
        "}{" +
        format.latexNodes(concept.effect.mip.partition[1].purview) + "^{f}" +
        "}"
  ]

  .directive 'mathjaxBind', ->
    restrict: 'A'
    controller: [
      '$scope'
      '$element'
      '$attrs'
      ($scope, $element, $attrs) ->
        $scope.$watch $attrs.mathjaxBind, (value) ->
          $script = angular.element("<script type='math/tex'>")
            .html(value or "")
          $element.html("")
          $element.append($script)
          MathJax.Hub.Queue ['Reprocess', MathJax.Hub, $element[0]]
    ]

  .directive 'vphiRepertoireChart', ->
    link: (scope, element, attrs) ->
      concept = scope.concept[attrs.direction]

      # Don't scale y axis to probabilities if the largest is greater than the
      # threshold.
      if scope.maxProbability > 0.2
        yAxis =
          max: 1
          tick:
            values: (i / 5 for i in [0..5])
          padding:top: 0

      padding =
        top: 0
        right: 5 * scope.numNodes
        bottom: 0
        left: 40

      chart = new RepertoireChart
        name: 'P'
        bindto: element[0]
        data: []
        height: 150
        padding: padding
        colors:
          'Unpartitioned': colors[attrs.direction]
          'Partitioned': colors.repertoire.partitioned
        x:
          tick:
            rotate: 60
            format: (x) ->
              # Low-Order bits correspond to Low-Index nodes.
              # NOTE: This should correspond to how NumPy's `flatten` function
              # works.
              utils.loliIndexToState(x, scope.numNodes).join(', ')
          label: (if attrs.direction is 'cause' then 'Past State' else 'Future State')
        y: yAxis or undefined

      chart.load [
        ['Unpartitioned'].concat concept.repertoire
        ['Partitioned'].concat concept.partitioned_repertoire
      ]
