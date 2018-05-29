'use strict'
###
# concept-space/ConceptSpaceDirective.coffee
###

# TODO use angular constant
HEIGHT = 500

# Check for lack of WebGL support.
if not Detector.webgl then Detector.addGetWebGLMessage()

module.exports = ->
  link: (scope, element, attrs) ->
    # Window resize handler.
    resize = ->
      # Get new width.
      width = $(element).parent().width()
      # Update canvas WebGl and CSS dimensions.
      $(element).children('canvas').attr 'width', width
      $(element).children('canvas').css 'width', width
      # Resize the canvas.
      scope.canvas.renderer.setSize(width, HEIGHT)
      # Update aspect ratio.
      scope.canvas.camera.aspect = width / HEIGHT
      # Update camera projection matrix.
      scope.canvas.camera.updateProjectionMatrix()
      scope.canvas.render()

    # Bind resize handler to window.
    $(window).resize(resize)

    # Add the canvas to the DOM.
    element.append(scope.canvas.renderer.domElement)

    init = ->
      # Initial render.
      scope.canvas.render()
      # Force a resize at start.
      resize()

    # Handle lost WebGL context.
    element.on 'webglcontextlost', (event) -> event.preventDefault()
    element.on 'webglcontextrestored', init

    # 3... 2... 1... BLAST OFF!
    init()
