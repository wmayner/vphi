'use strict'
###
# concept-list/concept/index.coffee
###

module.exports = angular.module 'vphi.conceptList.concept', [
  require('./chart').name
  require('./mathjax').name
]
  .controller 'conceptList.conceptCtrl', require './ConceptController'
