###
# controllers.coffee
###

console.log "HI"

window.vphi = angular.module 'vphi', []

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
