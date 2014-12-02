pyphi = require './graph-editor/pyphi'

# Initialize interface components
graphEditor = require './graph-editor.js'
conceptSpace = require './concept-space.js'


PRECISION = 6


# TODO dispense with jQuery and use d3 instead

#################
# Control panel #
#################

# Helpers

displayBigMip = (bigMip) ->
  # Round to PRECISION.
  phi = Number(bigMip.phi).toFixed(PRECISION)
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
  pyphi.bigMip(graphEditor.graph, displayBigMip).always ->
    btn.button 'reset'
    finishLoading()


$(document).ready ->

# Event handlers

control = $('#btn-calculate').mouseup(pressCalculate)

# Keyboard shorcuts

$(document).keydown (e) ->
  if e.keyCode is 13
    pressCalculate()
