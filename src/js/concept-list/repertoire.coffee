###
# concept-list/repertoire.coffee
###

class RepertoireChart
  constructor: (args) ->
    @_args = args
    @_data = args.data
    config =
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
          max: 1
          tick:
            values: (i / 5 for i in [0..5])
            count: 6
          padding:
            top: 0
            bottom: 0
      legend:show: false

    @_chart = c3.generate(config)

  load: (columns) ->
    @_chart.load
      columns: columns

module.exports = RepertoireChart
