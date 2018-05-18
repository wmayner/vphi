should = require 'should'
sinon = require 'sinon'
compute = require '../src/js/services/compute'
pyphi = require '../src/js/services/compute/pyphi'

exData = {bigMip: {}}

describe compute.name, ->
  computeService = null
  pyphiService = null

  beforeEach angular.mock.module 'vphi'

  # beforeEach () ->
  #   angular.mock.module ($provide) ->

  #     # class PyphiMock extends Pyphi

  #     #   majorComplex: (network, sucess, failure) ->
  #     #     return {always: sinon.spy()}

  #     $provide.service pyphi.name, PyPhiMock
  #     return  # coffee-script required hack

  beforeEach inject ($injector) ->
    pyphiService = $injector.get pyphi.name
    # Stub succesful remote phiserver call
    sinon.stub(pyphiService.pyphi, 'call').callsFake(
      (method, params, success, failure) ->
        success exData  # TODO: return actual data
        return {'always': (fn) -> fn()}
      )
    computeService = $injector.get compute.name

  describe 'update', ->
    it 'updates data attribute', ->
      computeService.update {bigMip: {phi: 1}}, {state: [0, 0, 0]}
      computeService.data.bigMip.phi.should.eql 1
      computeService.data.bigMip.state.should.eql [0, 0, 0]

  describe 'pyphiCall', ->
    it 'sets @calledMethod', ->
      computeService.majorComplex()
      computeService.calledMethod.should.eql 'majorComplex'

    it 'sets @callInProgress=true during the call', ->
      computeService.callInProgress.should.be.false()
      computeService.majorComplex((data) ->
       computeService.callInProgress.should.be.true())
      computeService.callInProgress.should.be.false()

    it 'updates @data', ->
      computeService.majorComplex()
      computeService.data.should.eql {bigMip: {state: [1, 0, 0]}}

    it 'sets result in local storage', ->
      localStorage.clear()
      computeService.majorComplex()
      # TODO test storage format
      stored = JSON.parse(localStorage.getItem('compute'))
      stored.should.containEql {VERSION: '1.0.7'}
      stored.should.containEql {PYPHI_VERSION: '1.0.0'}
      stored.should.containEql {calledMethod: 'majorComplex'}
