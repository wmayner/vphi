###
Main concept space script.
###

axes = require './concept-space/axes'
SplitView = require './concept-space/split-view'
JoinedView = require './concept-space/joined-view'


# Check for lack of WebGL support.
if not Detector.webgl then Detector.addGetWebGLMessage()


# ~~~~~~~~
# Globals
# ~~~~~~~~
TOGGLE_GRIDS_SELECTOR = '#toggle-grids'
SWITCH_VIEW_SELECTOR = '#switch-view'
RESET_CAMERA_SELECTOR = '#reset-camera'
CONTAINER_SELECTOR = '#concept-space-container'
SPLIT_VIEW_CANVAS_ID = 'split-view-canvas'
JOINED_VIEW_CANVAS_ID = 'joined-view-canvas'

# The currently active view.
activeView = undefined

# References to the containing DOM element.
$container = $(CONTAINER_SELECTOR)
container = $container[0]

# Width and height of the canvas.
width = $container.css('width')
height = 500

# Construct views.
splitView = new SplitView(container, width, height)
joinedView = new JoinedView(container, width, height)

# References to the two view canvases.
$splitViewCanvas = undefined
$joinedViewCanvas = undefined


# ~~~~~~~~
# Helpers
# ~~~~~~~~

resizeView = (view) ->
  view.renderer.setSize(width, height)
  # Update controls.
  view.controls.handleResize()
  # Update aspect ratio.
  view.camera.aspect = width / height
  # Update camera projection matrix.
  view.camera.updateProjectionMatrix()


resizeHandler = ->
  $canvas = $container.children('canvas')
  # Update global width.
  width = $container.width()
  # Update canvas WebGl and CSS dimensions.
  $canvas.attr('width', width)
  $canvas.css('width', width)
  # Resize the views.
  resizeView(splitView)
  resizeView(joinedView)


activateView = (view, $element) ->
  activeView = view
  view.controls.enabled = true
  $element.show()


deactivateView = (view, $element) ->
  view.controls.enabled = false
  $element.hide()


switchView = ->
  # Switch between split and joined view of past/future subspaces.
  if activeView is joinedView
    activateView(splitView, $splitViewCanvas)
    deactivateView(joinedView, $joinedViewCanvas)
  else if activeView is splitView
    activateView(joinedView, $joinedViewCanvas)
    deactivateView(splitView, $splitViewCanvas)


toggleGrids = ->
  joinedView.toggleGrids()
  splitView.toggleGrids()


# ~~~~~~~~~~~~~
# API
# ~~~~~~~~~~~~~
exports.display = (bigMip) ->
  joinedView.display(bigMip)
  splitView.display(bigMip)


init = ->
  # Tag the canvases with an ID.
  splitView.renderer.domElement.id = SPLIT_VIEW_CANVAS_ID
  joinedView.renderer.domElement.id = JOINED_VIEW_CANVAS_ID
  # Add the two view canvases to the DOM.
  $container.append(joinedView.renderer.domElement)
  $container.append(splitView.renderer.domElement)
  # Get jQuery references to the canvases.
  $splitViewCanvas = $('#' + SPLIT_VIEW_CANVAS_ID)
  $joinedViewCanvas = $('#' + JOINED_VIEW_CANVAS_ID)
  # Start with the joined view activated.
  activateView(joinedView, $joinedViewCanvas)
  deactivateView(splitView, $splitViewCanvas)
  # Force a resize at start.
  resizeHandler()


animate = ->
  splitView.animate()
  joinedView.animate()


# ~~~~~~~~~~~~~~~
# Event handlers
# ~~~~~~~~~~~~~~~
# Handle lost WebGL context.
$container.on('webglcontextlost', ((event) -> event.preventDefault()), false)
$container.on('webglcontextrestored', init, false)

# Listen for window resizing.
$(window).resize(resizeHandler)

# Bind the reset-camera handler to its button.
$(RESET_CAMERA_SELECTOR).mousedown -> activeView.resetControls()

# Bind the switch-view handler to its button.
$(SWITCH_VIEW_SELECTOR).mousedown -> switchView()

# Bind the toggle-grid handler to its button.
$(TOGGLE_GRIDS_SELECTOR).mousedown -> toggleGrids()


# 3... 2... 1... BLAST OFF!
$(document).ready ->
  init()
  animate()
  switchView()
