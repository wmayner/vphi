mechanism = require '../../src/js/services/network/mechanism'
should = require 'should'

testLogicGate = (gate, singleZero, singleOne, allZero, allOne, halfOne, oddMajorityOne, evenMinorityOne) ->
  it "should return #{singleZero} when single input is a 0", ->
    singleZero.should.eql mechanism[gate]([0])
  it "should return #{singleOne} when single input is a 1", ->
    singleOne.should.eql mechanism[gate]([1])
  it "should return #{allZero} when all inputs are 0", ->
    allZero.should.eql mechanism[gate]([0, 0, 0, 0, 0])
  it "should return #{allOne} when all inputs are 1", ->
    allOne.should.eql mechanism[gate]([1, 1, 1, 1, 1])
  it "should return #{halfOne} when half the inputs are 1", ->
    halfOne.should.eql mechanism[gate]([1, 0, 1, 0])
  it "should return #{oddMajorityOne} when an odd majority of inputs are 1", ->
    oddMajorityOne.should.eql mechanism[gate]([0, 1, 1, 0, 1])
  it "should return #{evenMinorityOne} when an even minority of inputs are 1", ->
    evenMinorityOne.should.eql mechanism[gate]([1, 0, 1, 0, 0])

testThresholdUnit = (type) ->
  f = mechanism['THRESHOLD'][type]
  v = (if type is 'ABOVE' then 1 else 0 )
  it 'should return 0 if the threshold is 2 and there are two 1s', ->
    f(2, [1, 1, 0]).should.eql 0
  it 'should return 0 if the threshold is 1 and there is a single 1', ->
    f(1, [1]).should.eql 0
  it "should return #{v} if the threshold is 3 and there are four 1s", ->
    v.should.eql f(3, [0, 1, 1, 0, 1, 1])
  it "should return #{v} if the threshold is 1 and there are two 1s", ->
    v.should.eql f(1, [1, 1])
  it "should return #{v} if the threshold is 0 and at least one input is 1", ->
    v.should.eql f(0, [1])
    v.should.eql f(0, [0, 0, 1])

describe 'mechanism', ->

  describe 'AND', ->
    testLogicGate('AND', 0, 1, 0, 1, 0, 0, 0)

  describe 'OR', ->
    testLogicGate('OR', 0, 1, 0, 1, 1, 1, 1)

  describe 'XOR', ->
    testLogicGate('XOR', 0, 1, 0, 1, 0, 1, 0)

  # describe 'COPY', ->
  #   testLogicGate('COPY', 0, 1, 0, 1, 0, 0, 0)

  # describe 'NOT', ->
  #   testLogicGate('NOT', 1, 0, 0, 1, 0, 0, 0)

  describe 'MAJ', ->
    testLogicGate('MAJ', 0, 1, 0, 1, 0, 1, 0)

  describe 'MIN', ->
    testLogicGate('MIN', 1, 0, 1, 0, 1, 0, 1)

  describe 'PAR', ->
    testLogicGate('PAR', 1, 0, 1, 0, 1, 0, 1)

  # describe 'THRESHOLD', ->
  #   describe 'ABOVE', -> testThresholdUnit('ABOVE')
  #   describe 'BELOW', -> testThresholdUnit('BELOW')
