utils = require '../src/js/utils'

describe 'allStates', ->
  it 'should return states in LOLI order', ->
    utils.allStates(2).should.eql [[0, 0], [1, 0], [0, 1], [1, 1]]
