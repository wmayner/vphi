###
# concept-space/index.coffee
###

axes = require './axes'
SplitView = require './split-view'
JoinedView = require './joined-view'


# Check for lack of WebGL support.
if not Detector.webgl then Detector.addGetWebGLMessage()


# ~~~~~~~~
# Globals
# ~~~~~~~~
TOGGLE_GRIDS_SELECTOR = '#toggle-grids'
TOGGLE_IGNORED_AXES_SELECTOR = '#toggle-ignored-axes'
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
joinedView = new JoinedView(width, height)

# References to the two view canvases.
$splitViewCanvas = undefined
$joinedViewCanvas = undefined


# ~~~~~~~~
# Helpers
# ~~~~~~~~

resizeView = (view) ->
  view.renderer.setSize(width, height)
  # Update aspect ratio.
  view.camera.aspect = width / height
  # Update camera projection matrix.
  view.camera.updateProjectionMatrix()
  view.render()


resizeHandler = ->
  $canvas = $container.children('canvas')
  # Update global width.
  width = $container.width()
  # Update canvas WebGl and CSS dimensions.
  $canvas.attr('width', width)
  $canvas.css('width', width)
  # Resize the views.
  resizeView(joinedView)


activateView = (view, $element) ->
  activeView = view
  view.controls.enabled = true
  $element.show()


deactivateView = (view, $element) ->
  view.controls.enabled = false
  $element.hide()


toggleGrids = ->
  joinedView.toggleGrids()


toggleIgnoredAxes = ->
  joinedView.toggleIgnoredAxes()


# ~~~~~~~~~~~~~
# API
# ~~~~~~~~~~~~~
exports.display = (vphiDataService) ->
  joinedView.display(vphiDataService)


init = ->
  # Tag the canvases with an ID.
  joinedView.renderer.domElement.id = JOINED_VIEW_CANVAS_ID
  # Add the two view canvases to the DOM.
  $container.append(joinedView.renderer.domElement)
  # Get jQuery references to the canvases.
  $joinedViewCanvas = $('#' + JOINED_VIEW_CANVAS_ID)
  # Start with the joined view activated.
  activateView(joinedView, $joinedViewCanvas)
  # Force a resize at start.
  resizeHandler()


render = ->
  joinedView.render()


# ~~~~~~~~~~~~~~~
# Event handlers
# ~~~~~~~~~~~~~~~
# Handle lost WebGL context.
$container.on('webglcontextlost', ((event) -> event.preventDefault()), false)
$container.on('webglcontextrestored', init, false)

# Listen for window resizing.
$(window).resize(resizeHandler)

# Bind event handlers.
$(RESET_CAMERA_SELECTOR).mousedown -> activeView.resetControls()
$(SWITCH_VIEW_SELECTOR).mousedown -> switchView()
$(TOGGLE_GRIDS_SELECTOR).mousedown -> toggleGrids()
$(TOGGLE_IGNORED_AXES_SELECTOR).mousedown -> toggleIgnoredAxes()


# 3... 2... 1... BLAST OFF!
$(document).ready ->
  init()
  render()
