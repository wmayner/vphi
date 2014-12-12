'use strict'

# Services

window.vphiServices = angular.module('vphiServices', [])

window.vphiServices.factory('PyPhi', ['ngResource',
  ($resource) ->
    return $resource('http://localhost:4000')
])
