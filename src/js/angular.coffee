###
# angular.coffee
###

utils = require './utils'
colors = require './colors'
Repertoire = require './concept-list/repertoire'

window.vphi = angular.module 'vphi', [
  'vphiDataService'
  'vphiConceptList'
]

window.vphiDataService = angular.module 'vphiDataService', []
  .factory 'vphiDataService', ->
    {"subsystem":{"cut":{"intact":[0,1,2],"severed":[]},"node_indices":[0,1,2]},"partitioned_constellation":[{"cause":{"partitioned_repertoire":[0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666],"repertoire":[0,0.16666666666666666,0.16666666666666666,0.16666666666666666,0,0.16666666666666666,0.16666666666666666,0.16666666666666666],"mip":{"partition":[{"mechanism":[],"purview":[1]},{"mechanism":[0],"purview":[2]}],"phi":0.166667,"direction":"past","partitioned_repertoire":[[[0.16666666666666666,0.3333333333333333],[0.16666666666666666,0.3333333333333333]]],"unpartitioned_repertoire":[[[0,0.3333333333333333],[0.3333333333333333,0.3333333333333333]]],"mechanism":[0],"purview":[1,2]}},"effect":{"partitioned_repertoire":[0.09375,0.09375,0.03125,0.03125,0.28125,0.28125,0.09375,0.09375],"repertoire":[0.0625,0.0625,0.0625,0.0625,0.1875,0.1875,0.1875,0.1875],"mip":{"partition":[{"mechanism":[],"purview":[1]},{"mechanism":[0],"purview":[]}],"phi":0.25,"direction":"future","partitioned_repertoire":[[[0.75],[0.25]]],"unpartitioned_repertoire":[[[0.5],[0.5]]],"mechanism":[0],"purview":[1]}},"phi":0.166667,"mechanism":[0]},{"cause":{"partitioned_repertoire":[0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333],"repertoire":[0.16666666666666666,0.16666666666666666,0.16666666666666666,0.16666666666666666,0.16666666666666666,0,0.16666666666666666,0],"mip":{"partition":[{"mechanism":[],"purview":[0]},{"mechanism":[1],"purview":[2]}],"phi":0.16666700000000023,"direction":"past","partitioned_repertoire":[[[0.3333333333333333,0.16666666666666666]],[[0.3333333333333333,0.16666666666666666]]],"unpartitioned_repertoire":[[[0.3333333333333333,0.3333333333333333]],[[0.3333333333333333,0]]],"mechanism":[1],"purview":[0,2]}},"effect":{"partitioned_repertoire":[0.09375,0.09375,0.03125,0.03125,0.28125,0.28125,0.09375,0.09375],"repertoire":[0.1875,0.1875,0.0625,0.0625,0.1875,0.1875,0.0625,0.0625],"mip":{"partition":[{"mechanism":[],"purview":[0]},{"mechanism":[1],"purview":[]}],"phi":0.25,"direction":"future","partitioned_repertoire":[[[0.25]],[[0.75]]],"unpartitioned_repertoire":[[[0.5]],[[0.5]]],"mechanism":[1],"purview":[0]}},"phi":0.16666700000000023,"mechanism":[1]}],"unpartitioned_constellation":[{"cause":{"partitioned_repertoire":[0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666],"repertoire":[0,0.16666666666666666,0.16666666666666666,0.16666666666666666,0,0.16666666666666666,0.16666666666666666,0.16666666666666666],"mip":{"partition":[{"mechanism":[],"purview":[1]},{"mechanism":[0],"purview":[2]}],"phi":0.166667,"direction":"past","partitioned_repertoire":[[[0.16666666666666666,0.3333333333333333],[0.16666666666666666,0.3333333333333333]]],"unpartitioned_repertoire":[[[0,0.3333333333333333],[0.3333333333333333,0.3333333333333333]]],"mechanism":[0],"purview":[1,2]}},"effect":{"partitioned_repertoire":[0.09375,0.09375,0.03125,0.03125,0.28125,0.28125,0.09375,0.09375],"repertoire":[0.0625,0.0625,0.0625,0.0625,0.1875,0.1875,0.1875,0.1875],"mip":{"partition":[{"mechanism":[],"purview":[1]},{"mechanism":[0],"purview":[]}],"phi":0.25,"direction":"future","partitioned_repertoire":[[[0.75],[0.25]]],"unpartitioned_repertoire":[[[0.5],[0.5]]],"mechanism":[0],"purview":[1]}},"phi":0.166667,"mechanism":[0]},{"cause":{"partitioned_repertoire":[0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333,0.16666666666666666,0.08333333333333333],"repertoire":[0.16666666666666666,0.16666666666666666,0.16666666666666666,0.16666666666666666,0.16666666666666666,0,0.16666666666666666,0],"mip":{"partition":[{"mechanism":[],"purview":[0]},{"mechanism":[1],"purview":[2]}],"phi":0.16666700000000023,"direction":"past","partitioned_repertoire":[[[0.3333333333333333,0.16666666666666666]],[[0.3333333333333333,0.16666666666666666]]],"unpartitioned_repertoire":[[[0.3333333333333333,0.3333333333333333]],[[0.3333333333333333,0]]],"mechanism":[1],"purview":[0,2]}},"effect":{"partitioned_repertoire":[0.09375,0.09375,0.03125,0.03125,0.28125,0.28125,0.09375,0.09375],"repertoire":[0.1875,0.1875,0.0625,0.0625,0.1875,0.1875,0.0625,0.0625],"mip":{"partition":[{"mechanism":[],"purview":[0]},{"mechanism":[1],"purview":[]}],"phi":0.25,"direction":"future","partitioned_repertoire":[[[0.25]],[[0.75]]],"unpartitioned_repertoire":[[[0.5]],[[0.5]]],"mechanism":[1],"purview":[0]}},"phi":0.16666700000000023,"mechanism":[1]},{"cause":{"partitioned_repertoire":[0.125,0.125,0.125,0.125,0.125,0.125,0.125,0.125],"repertoire":[0.25,0.25,0,0,0,0,0.25,0.25],"mip":{"partition":[{"mechanism":[],"purview":[0]},{"mechanism":[2],"purview":[1]}],"phi":0.5,"direction":"past","partitioned_repertoire":[[[0.25],[0.25]],[[0.25],[0.25]]],"unpartitioned_repertoire":[[[0.5],[0]],[[0],[0.5]]],"mechanism":[2],"purview":[0,1]}},"effect":{"partitioned_repertoire":[0.125,0.125,0,0,0.375,0.375,0,0],"repertoire":[0.25,0.25,0,0,0.25,0.25,0,0],"mip":{"partition":[{"mechanism":[],"purview":[0]},{"mechanism":[2],"purview":[1]}],"phi":0.25,"direction":"future","partitioned_repertoire":[[[0.25],[0]],[[0.75],[0]]],"unpartitioned_repertoire":[[[0.5],[0]],[[0.5],[0]]],"mechanism":[2],"purview":[0,1]}},"phi":0.25,"mechanism":[2]},{"cause":{"partitioned_repertoire":[0,0.125,0.25,0.125,0,0.125,0.25,0.125],"repertoire":[0,0.25,0.25,0.25,0,0,0.25,0],"mip":{"partition":[{"mechanism":[],"purview":[0]},{"mechanism":[0,1],"purview":[1,2]}],"phi":0.24999975000000002,"direction":"past","partitioned_repertoire":[[[0,0.125],[0.25,0.125]],[[0,0.125],[0.25,0.125]]],"unpartitioned_repertoire":[[[0,0.25],[0.25,0.25]],[[0,0],[0.25,0]]],"mechanism":[0,1],"purview":[0,1,2]}},"effect":{"partitioned_repertoire":[0.09375,0.09375,0.03125,0.03125,0.28125,0.28125,0.09375,0.09375],"repertoire":[0,0.1875,0,0.0625,0,0.5625,0,0.1875],"mip":{"partition":[{"mechanism":[0],"purview":[]},{"mechanism":[1],"purview":[2]}],"phi":0.5,"direction":"future","partitioned_repertoire":[[[0.5,0.5]]],"unpartitioned_repertoire":[[[0,1]]],"mechanism":[0,1],"purview":[2]}},"phi":0.24999975000000002,"mechanism":[0,1]},{"cause":{"partitioned_repertoire":[0.25,0.25,0,0,0,0,0.25,0.25],"repertoire":[0.3333333333333333,0.3333333333333333,0,0,0,0,0.16666666666666666,0.16666666666666666],"mip":{"partition":[{"mechanism":[1],"purview":[]},{"mechanism":[2],"purview":[0,1]}],"phi":0.333334,"direction":"past","partitioned_repertoire":[[[0.5],[0]],[[0],[0.5]]],"unpartitioned_repertoire":[[[0.6666666666666666],[0]],[[0],[0.3333333333333333]]],"mechanism":[1,2],"purview":[0,1]}},"effect":{"partitioned_repertoire":[0.1875,0.1875,0.0625,0.0625,0.1875,0.1875,0.0625,0.0625],"repertoire":[0.375,0.375,0.125,0.125,0,0,0,0],"mip":{"partition":[{"mechanism":[1],"purview":[]},{"mechanism":[2],"purview":[0]}],"phi":0.5,"direction":"future","partitioned_repertoire":[[[0.5]],[[0.5]]],"unpartitioned_repertoire":[[[1]],[[0]]],"mechanism":[1,2],"purview":[0]}},"phi":0.333334,"mechanism":[1,2]},{"cause":{"partitioned_repertoire":[0.3333333333333333,0.3333333333333333,0,0,0,0,0.3333333333333333,0],"repertoire":[0,0.5,0,0,0,0,0.5,0],"mip":{"partition":[{"mechanism":[0],"purview":[]},{"mechanism":[1,2],"purview":[0,1,2]}],"phi":0.499998999999,"direction":"past","partitioned_repertoire":[[[0.3333333333333333,0.3333333333333333],[0,0]],[[0,0],[0.3333333333333333,0]]],"unpartitioned_repertoire":[[[0,0.5],[0,0]],[[0,0],[0.5,0]]],"mechanism":[0,1,2],"purview":[0,1,2]}},"effect":{"partitioned_repertoire":[0.375,0.375,0.125,0.125,0,0,0,0],"repertoire":[0,0.75,0,0.25,0,0,0,0],"mip":{"partition":[{"mechanism":[0],"purview":[]},{"mechanism":[1,2],"purview":[0,2]}],"phi":0.5,"direction":"future","partitioned_repertoire":[[[0.5,0.5]],[[0,0]]],"unpartitioned_repertoire":[[[0,1]],[[0,0]]],"mechanism":[0,1,2],"purview":[0,2]}},"phi":0.499998999999,"mechanism":[0,1,2]}],"phi":1.9166640364566252,"cut_subsystem":{"cut":{"intact":[2],"severed":[0,1]},"node_indices":[0,1,2]}}

window.vphiConceptList = angular.module 'vphiConceptList', [
  'vphiDataService'
]
  .controller('vphiConceptListCtrl', [
    '$scope'
    'vphiDataService'
    ($scope, vphiDataService) ->

      $scope.concepts = vphiDataService.unpartitioned_constellation
      $scope.numNodes = vphiDataService.subsystem.node_indices.length

      $scope.getSmallPhi = (concept) ->
        return utils.formatPhi(concept.phi)

      $scope.getMechanism = (concept) ->
        return (utils.LABEL[n] for n in concept.mechanism).join(' ')
  ])
  .directive('vphiConcept', ->
    link: ($scope, $element, $attrs) ->
  )
  .directive('vphiRepertoireChart', ->
    link: ($scope, $element, $attrs) ->
      concept = $scope.concept[$attrs.direction]
      # TODO refactor into a networkService?
      Repertoire
        name: 'P'
        bindto: $element[0]
        data: [
          ['Unpartitioned'].concat concept.repertoire
          ['Partitioned'].concat concept.partitioned_repertoire
        ]
        height: 150
        colors:
          'Unpartitioned': colors[$attrs.direction]
          'Partitioned': colors.repertoire.partitioned
        x:
          tick:
            count: concept.repertoire.length
            rotate: 60
            format: (x) ->
              utils.loliIndexToState(d3.round(x, 0), $scope.numNodes).join(', ')
          label: (if $attrs.direction is 'cause' then 'Past State' else 'Future State')
  )
