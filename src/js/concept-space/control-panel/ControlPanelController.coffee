'use strict'
###
# concept-space/control-panel/ControlPanelController.coffee
###

module.exports = [
  '$scope'
  ($scope) ->
    $scope.resetCamera = -> $scope.canvas.resetCamera()
    $scope.toggleGrids = -> $scope.canvas.toggleGrids()
    $scope.toggleIgnoredAxes = -> $scope.canvas.toggleIgnoredAxes()
    $scope.switchView = ->
]
