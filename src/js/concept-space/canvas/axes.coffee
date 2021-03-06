###
# concept-space/axes.coffee
###

colors = require '../../colors'
rotate = require './rotate'

π = Math.PI
RENDERED_AXIS_LINE_WIDTH = 3
IGNORED_AXIS_LINE_WIDTH = 2
IGNORED_AXIS_COLOR = 0x999999
# World axis vectors to use in rotation.
X_AXIS = new THREE.Vector3(1, 0, 0)
Y_AXIS = new THREE.Vector3(0, 1, 0)
Z_AXIS = new THREE.Vector3(0, 0, 1)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helpers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Forked from
# https://github.com/mrdoob/three.js/blob/master/src/extras/helpers/AxisHelper.js
AxisHelper = (config) ->
  size = config.size or 1
  coords = config.coords
  vertices = new Float32Array([
    0, 0, 0,  coords[0][0], coords[0][1], coords[0][2],
    0, 0, 0,  coords[1][0], coords[1][1], coords[1][2],
    0, 0, 0,  coords[2][0], coords[2][1], coords[2][2],
  ])
  geometry = new THREE.BufferGeometry()
  geometry.addAttribute "position", new THREE.BufferAttribute(vertices, 3)
  geometry.addAttribute "color", new THREE.BufferAttribute(config.colors, 3)
  config.lineoptions.vertexColors = THREE.VertexColors
  material = new THREE.LineBasicMaterial(config.lineoptions)
  THREE.Line.call(this, geometry, material, THREE.LinePieces)
  return

AxisHelper:: = Object.create(THREE.Line::)


makeVector = (point, lineoptions) ->
  material = new THREE.LineBasicMaterial(lineoptions)
  geometry = new THREE.Geometry();
  geometry.vertices.push(
    new THREE.Vector3(0, 0, 0),
    point
  )
  return new THREE.Line(geometry, material)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module.exports =

  # TODO refactor these split/joined functions
  drawSplitIgnored: (scene, numStates, direction, renderedDimensions) ->
    # Make a circle.
    material = new THREE.LineBasicMaterial()
    geometry = new THREE.CircleGeometry(.5, numStates)
    circle = new THREE.Line(geometry, material)
    # Remove center vertex.
    geometry.vertices.shift()
    # Remove vertices corresponding to axes that are rendered, since these will
    # be displayed as the main coordinate axes.
    for d in renderedDimensions[direction]
      geometry.vertices.splice(d, d + 1)
    # Shift the vertices towards the past or future octants.
    shift = 0.15
    if direction is 'past'
      shift = -shift
    for v in geometry.vertices
      v.z += shift
    # Make the axes.
    axes = (makeVector(v,
      color: IGNORED_AXIS_COLOR
      linewidth: IGNORED_AXIS_LINE_WIDTH
    ) for v in geometry.vertices)
    # Rotate them into place.
    for axis in axes
      rotate.aroundWorldAxis(axis, Z_AXIS, π/4)
      rotate.aroundWorldAxis(axis, X_AXIS, 3*π/4)
      rotate.aroundWorldAxis(axis, Y_AXIS, π/4)
      scene.add(axis)
    return axes

  drawJoinedIgnored: (scene, numStates, renderedDimensions) ->
    # Make a circle.
    material = new THREE.LineBasicMaterial()
    geometry = new THREE.CircleGeometry(.5, (2 * numStates))
    circle = new THREE.Line(geometry, material)
    # Remove center vertex.
    geometry.vertices.shift()
    # Remove vertices corresponding to axes that are rendered, since these will
    # be displayed as the main coordinate axes.
    for d in renderedDimensions
      geometry.vertices.splice(d.index, d.index + 1)
    # Make the axes.
    axes = (makeVector(v,
      color: IGNORED_AXIS_COLOR
      linewidth: IGNORED_AXIS_LINE_WIDTH
    ) for v in geometry.vertices)
    # Rotate them into place.
    for axis in axes
      rotate.aroundWorldAxis(axis, Z_AXIS, π/4)
      rotate.aroundWorldAxis(axis, X_AXIS, 3*π/4)
      rotate.aroundWorldAxis(axis, Y_AXIS, π/4)
      scene.add(axis)
    return axes

  drawSplit: (scene) ->
    pastColor = [
      colors.cause.r / 255
      colors.cause.g / 255
      colors.cause.b / 255
    ]
    futureColor = [
      colors.effect.r / 255
      colors.effect.g / 255
      colors.effect.b / 255
    ]
    past_axis = new AxisHelper(
      coords: [
        [-1, 0, 0]
        [0, -1, 0]
        [0, 0, -1]
      ]
      colors: new Float32Array([]
        .concat(pastColor).concat(pastColor)
        .concat(pastColor).concat(pastColor)
        .concat(pastColor).concat(pastColor)
        # 1.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        # 0.0, 1.0, 0.0,  0.0, 1.0, 0.0,
        # 0.0, 0.0, 1.0,  0.0, 0.0, 1.0,
      )
      lineoptions: {linewidth: RENDERED_AXIS_LINE_WIDTH}
    )
    scene.add(past_axis)
    future_axis = new AxisHelper(
      coords: [
        [1, 0, 0]
        [0, 1, 0]
        [0, 0, 1]
      ]
      colors: new Float32Array([]
        .concat(futureColor).concat(futureColor)
        .concat(futureColor).concat(futureColor)
        .concat(futureColor).concat(futureColor)
        # 1.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        # 0.0, 1.0, 0.0,  0.0, 1.0, 0.0,
        # 0.0, 0.0, 1.0,  0.0, 0.0, 1.0,
      )
      lineoptions: {linewidth: RENDERED_AXIS_LINE_WIDTH}
    )
    scene.add(future_axis)

  drawJoined: (scene, renderedDimensions) ->
    # X, Y, Z proceed from highest to lowest variance.
    pastColor = [
      colors.cause.r / 255
      colors.cause.g / 255
      colors.cause.b / 255
    ]
    futureColor = [
      colors.effect.r / 255
      colors.effect.g / 255
      colors.effect.b / 255
    ]
    axisColors = []
    # Build color array, one row per axis.
    for direction in (d.direction for d in renderedDimensions)
      # Double concatenation since each row is a gradient with two RGB
      # colors.
      if direction is 'cause'
        axisColors = axisColors.concat(pastColor).concat(pastColor)
      else if direction is 'effect'
        axisColors = axisColors.concat(futureColor).concat(futureColor)
      else throw Error("Invalid direction.")
    axes = new AxisHelper(
      coords: [
        [1, 0, 0]
        [0, 1, 0]
        [0, 0, 1]
      ]
      colors: new Float32Array(axisColors)
      lineoptions: {linewidth: RENDERED_AXIS_LINE_WIDTH}
    )
    scene.add(axes)
