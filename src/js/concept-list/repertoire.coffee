###
# concept-list/repertoire.coffee
###

class Repertoire
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

  _update: =>
    @_chart.load(columns: [@_data])

  load: (dataIndex) =>
    d = @_args.data[dataIndex]
    @_data = [@_args.name]
      .concat(@_args.data[0...(dataIndex + 1)])
      .concat(null for i in [(dataIndex + 1)...@_args.data.length])
    @_update()

  clear: =>
    @_data = [@_args.name]
      .concat(null for d in @_args.data)
    @_update()

module.exports = Repertoire
