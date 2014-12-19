'use strict'

# AngularJS
ngControllers = require './controllers'
ngServices = require './services'

pyphi = require './graph-editor/pyphi'
error = require './errors'

# Initialize interface components
graphEditor = require './graph-editor'
conceptSpace = require './concept-space'


PRECISION = 6


# TODO dispense with jQuery and use d3 instead

#################
# Control panel #
#################

# Helpers

displayBigMip = (bigMip) ->
  # Round to PRECISION.
  phi = utils.formatPhi(bigMip.phi)
  # Display the result.
  $('#output-phi').html(phi)
  # Draw the unpartitioned constellation.
  conceptSpace.display(bigMip)

cooldown = false

startLoading = ->
  $('#output-phi').html('···')
  $('#concept-space-loading-spinner').removeClass('hidden')
  $('#concept-space-loading-spinner').show()
  $('#concept-space-overlay').removeClass('hidden')
  $('#concept-space-overlay').show()

finishLoading = ->
  $('#concept-space-loading-spinner').fadeOut(400, -> cooldown = false)
  $('#concept-space-overlay').fadeOut(400)

pressCalculate = ->
  return if cooldown
  cooldown = true
  btn = $('#btn-calculate')
  btn.button 'loading'
  startLoading()
  try
    pyphi.bigMip(graphEditor.graph, displayBigMip).always ->
      btn.button 'reset'
      finishLoading()
  catch e
    btn.button 'reset'
    finishLoading()
    switch e.code
      when 1
        # TODO display "invalid past state message"
        console.error(e.message)
      when 2
        # TODO display "network size limit exceeded message"
        console.error(e.message)


$(document).ready ->

# Event handlers

control = $('#btn-calculate').mouseup(pressCalculate)

# Keyboard shorcuts

$(document).keydown (e) ->
  if e.keyCode is 13
    pressCalculate()
