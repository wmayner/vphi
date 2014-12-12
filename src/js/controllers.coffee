'use strict'

# Controllers

window.vphi = angular.module('vphiControllers', [])

window.vphi.controller 'RepertoireListCtrl', ($scope) ->
  $scope.sup = 'no'
  $scope.pastRepertoires = [
    'past'
    'hi'
    'there'
  ]
  $scope.futureRepertoires = [
    'future'
    'hi'
    'there'
  ]

window.vphi.controller 'ConceptListCtrl', ($scope) ->
