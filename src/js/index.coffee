###
# index.coffee
###

'use strict'

utils = require './utils'
colors = require './colors'
formatter = require './format'
conceptSpace = require './concept-space'


window.vphi = angular.module 'vphi', [
  'vphiGraphService'
  'vphiDataService'
  'vphiFormatterService'
  'vphiGraphEditor'
  'vphiMainControls'
  'vphiOutputSummary'
  'vphiConceptList'
]
  .constant 'version', require('../../package.json').version


window.vphiDataService = angular.module 'vphiDataService', []
  .factory 'vphiDataService', [
    '$rootScope'
    'vphiGraphService'
    ($rootScope, vphiGraphService) ->

      pyphi = require './pyphi'

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
          log.debug "DATA_SERVICE: Calling `#{method}`..."
          @callInProgress = true
          pyphi[method](vphiGraphService.graph, (bigMip) =>
            @update(bigMip)
            @callInProgress = false
            $rootScope.$apply success
          ).always(-> $rootScope.$apply always)

        update: (bigMip) =>
          log.debug "DATA_SERVICE: Updating..."
          @data = bigMip
          # Record current and past state.
          # TODO just attach these to the service.
          @data.currentState = vphiGraphService.graph.currentState
          @data.pastState = vphiGraphService.graph.pastState
          log.debug "DATA_SERVICE: Data:"
          log.debug @data
          window.phidata = @data

          # Select the subsystem that was returned
          vphiGraphService.graph.setSelectedSubsystem(@data.subsystem.node_indices)
          vphiGraphService.update()

          log.debug "DATA_SERVICE: Broadcasting data update."
          $rootScope.$broadcast 'vphiDataUpdated'
          return
  ]


window.vphiGraphService = angular.module 'vphiGraphService', [
]
  .factory 'vphiGraphService', [
    '$rootScope'
    '$timeout'
    ($rootScope, $timeout) ->

      # Initialize the graph editor.
      graphEditor = require './graph-editor'
      examples = require './graph-editor/examples'

      return new class PhiGraphService
        constructor: ->
          console.log 'PhiGraphService.constructor'
          # Load previous graph if available.
          storedGraph = localStorage.getItem 'vphiGraph'
          if storedGraph
            console.log "LOADING"
            graphEditor.load(storedGraph)
          # Grab reference to the graph.
          @graph = graphEditor.graph
          console.log @graph
          # Inject the event broadcasting hook.
          @graph.onUpdate = @update

        update: =>
          console.log 'PhiDataService.update'
          graphEditor.update()
          console.log @graph
          localStorage.setItem('vphiGraph', @graph.toJSON())
          log.debug "GRAPH_SERVICE: Broadcasting graph update."
          # Since graph updates can trigger more graph updates, we need to use
          # $timeout to allow any $apply calls to finish before broadcasting
          # another change. Otherwise there may be nested $apply's, which
          # Angular doesn't allow.
          $timeout -> $rootScope.$broadcast 'vphiGraphUpdated', 0
          return
  ]

window.vphiGraphEditor = angular.module 'vphiGraphEditor', [
  'vphiGraphService'
]
  .controller 'vphiGraphEditorCtrl', [
    '$scope'
    'vphiGraphService'
    'vphiFormatterService'
    ($scope, vphiGraphService, format) ->
      update = ->
        $scope.currentPastState = vphiGraphService.graph.pastState?.join(', ') or null
        $scope.possiblePastStates = vphiGraphService.graph.getPossiblePastStates()
        $scope.nodes = format.nodes([0...vphiGraphService.graph.nodeSize]).join(', ')

      # Intialize.
      update()

      $scope.select = (pastState) ->
        log.debug "GRAPH_CONTROLS: Setting past state to [#{pastState}]."
        vphiGraphService.graph.setPastState(pastState)

      $scope.$on 'vphiGraphUpdated', ->
        log.debug 'GRAPH_CONTROLS: Receieved graph update.'
        $scope.$apply update
  ]


window.vphiFormatterService = angular.module 'vphiFormatterService', [
]
  .factory 'vphiFormatterService', [
    'vphiGraphService'
    (vphiGraphService) -> formatter
  ]


window.vphiControls = angular.module 'vphiMainControls', [
  'vphiDataService'
]
  .controller 'vphiMainCtrl', [
    '$scope'
    'vphiGraphService'
    'vphiDataService'
    ($scope, vphiGraphService, vphiDataService) ->
      btns = $('.btn-calculate')
      btnSelectedSubsystem = $('#btn-selected-subsystem')
      btnMainComplex = $('#btn-main-complex')

      method2btn =
        'mainComplex': btnMainComplex
        'bigMip': btnSelectedSubsystem

      $scope.$on 'vphiGraphUpdated', ->
        if vphiGraphService.graph.pastState and not vphiDataService.callInProgress
          btns.removeClass 'disabled'
        else
          btns.addClass 'disabled'

      btnCooldown = false

      startLoading = ->
        $('#concept-space-loading-spinner').removeClass 'hidden'
        $('#concept-space-loading-spinner').show()
        $('#concept-space-overlay').removeClass 'hidden'
        $('#concept-space-overlay').show()
        btns.addClass('disabled')

      finishLoading = ->
        $('#concept-space-loading-spinner').fadeOut 400, ->
          btnCooldown = false
        $('#concept-space-overlay').fadeOut 400
        btns.removeClass('disabled')

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

      $scope.calculate = (method) ->
        return if btnCooldown or not vphiGraphService.graph.pastState
        btn = method2btn[method]
        registerClick(btn)
        vphiDataService[method](
          success(btn), always(btn)
        )
  ]


window.vphiOutputSummary = angular.module 'vphiOutputSummary', []
  .controller 'vphiOutputSummaryCtrl', [
    '$scope'
    'vphiDataService'
    'vphiFormatterService'
    ($scope, vphiDataService, format) ->
      $scope.format = format

      $scope.currentState = null
      $scope.title = 'Subsystem'
      $scope.nodes = []
      $scope.cut = null
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
    'vphiFormatterService'
    ($scope, format) ->
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

    RepertoireChart = require './concept-list/repertoire'

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
