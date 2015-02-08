'use strict'
###
# concept-list/chart/ChartDirective.coffee
###

class RepertoireChart
  constructor: (args) ->
    @_args = args
    @_data = args.data
    config =
      padding: args.padding
      size:height: args.height
      bindto: args.bindto
      data:
        colors: args.colors
        columns: @_data
        type: 'bar'
      grid:
        x:show: false
        y:show: true
      bar:
        width:ratio: 0.8
        zerobased: true
      axis:
        x:
          tick:
            count: args.x?.tick?.count
            rotate: args.x?.tick?.rotate or 0
            culling: false
            format: args.x?.tick?.format or (x) -> x
          label:
            show: true
            text: args.x?.label or ''
            position: 'inner-right'
        y:
          min: 0
          max: args.y?.max
          tick:
            values: args.y?.tick?.values
            count: 6
            format: (y) -> d3.round(y, 2)
          padding:
            top: args.y?.padding?.top
            bottom: 0
      legend:show: false

    @_chart = c3.generate(config)

  load: (columns) ->
    # Workaround for C3 charts not initially sizing correctly.
    id = setTimeout (
      =>
        @_chart.load(columns: columns)
        $(window).trigger('resize')
      ), 0

module.exports = RepertoireChart
