###
# concept-space/axes.coffee
###

rotate = require './rotate'

π = Math.PI
RENDERED_AXIS_LINE_WIDTH = 5
IGNORED_AXIS_LINE_WIDTH = 3
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
  coords = config.coords
  colors = config.colors
  lineoptions = config.lineoptions
  size = size or 1
  vertices = new Float32Array([
    0, 0, 0,  coords[0][0], coords[0][1], coords[0][2],
    0, 0, 0,  coords[1][0], coords[1][1], coords[1][2],
    0, 0, 0,  coords[2][0], coords[2][1], coords[2][2],
  ])
  geometry = new THREE.BufferGeometry()
  geometry.addAttribute "position", new THREE.BufferAttribute(vertices, 3)
  geometry.addAttribute "color", new THREE.BufferAttribute(colors, 3)
  lineoptions.vertexColors = THREE.VertexColors
  material = new THREE.LineBasicMaterial(lineoptions)
  THREE.Line.call(this, geometry, material, THREE.LinePieces)
  return

AxisHelper:: = Object.create(THREE.Line::)


drawVector = (point, lineoptions) ->
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
    axes = (drawVector(v,
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
    axes = (drawVector(v,
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
    past_axis = new AxisHelper(
      coords: [
        [-1, 0, 0]
        [0, -1, 0]
        [0, 0, -1]
      ]
      colors: new Float32Array([
        # 0.2, 0.8, 1.0,  0.2, 0.8, 1.0,
        # 0.1, 0.2, 0.9,  0.1, 0.2, 0.9,
        # 0.4, 0.4, 1.0,  0.4, 0.4, 1.0,
        0.14, 0.54, 0.82,  0.14, 0.54, 0.82,
        0.14, 0.54, 0.82,  0.14, 0.54, 0.82,
        0.14, 0.54, 0.82,  0.14, 0.54, 0.82,
        # 0.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        # 0.0, 0.0, 0.0,  0.0, 1.0, 0.0,
        # 0.0, 0.0, 0.0,  0.0, 0.0, 1.0,
      ])
      lineoptions: {linewidth: RENDERED_AXIS_LINE_WIDTH}
    )
    scene.add(past_axis)
    future_axis = new AxisHelper(
      coords: [
        [1, 0, 0]
        [0, 1, 0]
        [0, 0, 1]
      ]
      colors: new Float32Array([
        # 0.8, 1.0, 0.3,  0.8, 1.0, 0.3,
        # 0.1, 0.5, 0.2,  0.1, 0.5, 0.2,
        # 0.4, 0.9, 0.4,  0.4, 0.9, 0.4,
        0.1, 0.5, 0.2,  0.1, 0.5, 0.2,
        0.1, 0.5, 0.2,  0.1, 0.5, 0.2,
        0.1, 0.5, 0.2,  0.1, 0.5, 0.2,
        # 1.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        # 0.0, 1.0, 0.0,  0.0, 1.0, 0.0,
        # 0.0, 0.0, 1.0,  0.0, 0.0, 1.0,
      ])
      lineoptions: {linewidth: RENDERED_AXIS_LINE_WIDTH}
    )
    scene.add(future_axis)

  drawJoined: (scene) ->
    future_axis = new AxisHelper(
      coords: [
        [1, 0, 0]
        [0, 1, 0]
        [0, 0, 1]
      ]
      colors: new Float32Array([
        0.8, 0.8, 0.8,  0.8, 0.8, 0.8,
        0.8, 0.8, 0.8,  0.8, 0.8, 0.8,
        0.8, 0.8, 0.8,  0.8, 0.8, 0.8,
      ])
      lineoptions: {linewidth: RENDERED_AXIS_LINE_WIDTH}
    )
    scene.add(future_axis)
