'use strict'
###
# concept-list/index.coffee
###

concept = require './concept'

module.exports = angular.module 'vphi.conceptList', [
  concept.name
]
  .controller 'conceptListCtrl', require './ConceptListController'
