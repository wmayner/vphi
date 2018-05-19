'use strict'
###
# concept-list/concept/index.coffee
###

module.exports = angular.module 'vphi.conceptList.concept', [
  require('./chart').name
]
  .controller 'conceptList.conceptCtrl', require './ConceptController'
  # .filter 'formatLatex', ->
  #   return (mechanism) ->
  #     return mechanism
  .filter 'asLatex', ->
     return (string) ->
       return '\\( ' + string + ' \\)'
  .component 'partition', {
    bindings: {
      partition: '<'
      format: '<'  # TODO: pull from outer scope
      direction: '@'  # 'p' or 'f' -> TODO: pull from MIP
    }
    controller: ->
      this.fmt = (nodes) =>
        return this.format.latexNodes nodes

      this.formatPartition = () =>
        partition = this.partition
        return """
          \\frac{
            #{this.fmt(partition.part0.mechanism)}^{c}
          }{
            #{this.fmt(partition.part0.purview)}^{#{this.direction}}
          } \\times \\frac{
            #{this.fmt(partition.part1.mechanism)}^{c}
          }{
            #{this.fmt(partition.part1.purview)}^{#{this.direction}}
          }"""
      return
    template: '''
      <div class="vphi-label"> Partitioned </div>
      <div class="math-output"> {{ $ctrl.formatPartition()|asLatex }} </div>
    '''
  }
