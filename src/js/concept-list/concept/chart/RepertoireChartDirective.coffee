'use strict'
###
# concept-list/chart/ChartDirective.coffee
###

colors = require '../../../colors'
utils = require '../../../utils'
RepertoireChart = require './RepertoireChart'

module.exports = ->
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
      bottom: 5
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
            # For the display, we use the "High-Order bits correspond to
            # Low-Index nodes" convention.
            # NOTE: This should correspond to how NumPy's `flatten` function
            # works.
            utils.holiIndexToState(x, scope.numNodes).join(', ')
        label: (
          if attrs.direction is 'cause' then 'Past State' else 'Future State'
        )
      y: yAxis or undefined

    log.debug "CONCEPT_LIST: Loading #{attrs.direction} repertoire chart " +
      "for concept #{scope.$index}."
    chart.load [
      ['Unpartitioned'].concat concept.repertoire
      ['Partitioned'].concat concept.partitioned_repertoire
    ]
