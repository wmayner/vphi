should = require 'should'
sinon = require 'sinon'
require 'should-sinon'


describe 'networkEditor', ->
  describe 'networkEditor.ControlPanelCtrl', ->
    beforeEach angular.mock.module 'vphi'

    controller = null

    beforeEach inject ($controller) ->
      controller = $controller 'networkEditor.ControlPanelCtrl'

    describe 'exportNetwork', ->
      it 'should save file', ->
        saveAs = sinon.stub window, 'saveAs'
        controller.exportNetwork()
        saveAs.should.be.calledOnce()

    describe 'importNetwork', ->
      # TODO
