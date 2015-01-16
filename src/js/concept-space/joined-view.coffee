###
# concept-space/joined-view.coffee
#
# Returns a scene initialized with all the static stuff necessary to represent
# concept space.
###

axes = require './axes'
Label = require './label'
utils = require './utils'
globalUtils = require '../utils'


π = Math.PI
# THREE.js world.
MAX_CONCEPT_RADIUS = 0.5
# Font-size in pixels.
MIN_CONCEPT_LABEL_SIZE = 14
MAX_CONCEPT_LABEL_SIZE = 60

scene = new THREE.Scene()


getRenderedDimensions = (constellation, numNodes) ->
  numStates = Math.pow(2, numNodes)
  pastDistributions = (c.cause.repertoire for c in constellation)
  futureDistributions = (c.effect.repertoire for c in constellation)
  distributions = pastDistributions.concat(futureDistributions)
  renderedDimensions = utils.sortStatesByVariance( \
      distributions, (2 * numStates))[-3...]
  renderedDimensions = ({
    direction: (if d >= numStates then 'effect' else 'cause')
    index: (if d >= numStates then d - numStates else d)
  } for d in renderedDimensions)
  return renderedDimensions


class JoinedView
  constructor: (width, height) ->

    @scene = scene

    @ignoredAxes = []
    @constellation = []
    @labels = []

    # ~~~~~~~~~
    # Lighting.
    # ~~~~~~~~~
    scene.add(new THREE.AmbientLight(0x999999))
    light = new THREE.PointLight(0xffffff, 1, 0)
    light.position.set(2, 2, 2)
    scene.add(light)
    scene.add(new THREE.HemisphereLight(0xdddddd, 0x444444))
    # ~~~~~~~~~

    # Draw the past and future axes.
    axes.drawJoined(@scene)

    # ~~~~~~~~~~~~~~~~~~~~
    # Draw the axis grids.
    # ~~~~~~~~~~~~~~~~~~~~
    gridStep = 0.2
    # XY
    xyGrid = new THREE.GridHelper(0.5, 0.2)
    xyGrid.rotation.set(π/2, 0, 0)
    xyGrid.position.set(0.5, 0.5, 0.0)
    # YZ
    yzGrid = new THREE.GridHelper(0.5, gridStep)
    yzGrid.rotation.set(0, π/2, 0)
    yzGrid.position.set(0.5, 0.0, 0.5)
    # ZX
    zxGrid = new THREE.GridHelper(0.5, gridStep)
    zxGrid.rotation.set(0, 0, π/2)
    zxGrid.position.set(0.0, 0.5, 0.5)

    @grids = [xyGrid, yzGrid, zxGrid]

    for grid in @grids
      @scene.add(grid)
    # ~~~~~~~~~~~~~~~~~~~~

    # Initialize the renderer.
    @renderer = new THREE.WebGLRenderer(alpha: false)
    @renderer.setSize(width, height)

    # Initialize the camera.
    @camera = new THREE.PerspectiveCamera(20, width / height, 0.0001, 1000)
    @scene.add(@camera)
    @camera.position.set(1.5, 1.5, 1.5)

    # Initialize the camera controls.
    @controls = new THREE.OrbitControls(@camera, @renderer.domElement)

    @controls.noRotate = false
    @controls.rotateSpeed = 1.5

    @controls.noZoom = false
    @controls.zoomSpeed = 2

    @controls.noPan = false
    @controls.keyPanSpeed = 1.0

    @controls.addEventListener 'change', @render

    # Start with the default focal point and camera position.
    @resetControls()
    return

  drawIgnoredAxes: (numStates, renderedDimensions) ->
    @ignoredAxes = @ignoredAxes.concat(
      axes.drawJoinedIgnored(scene, numStates - 3, renderedDimensions)
    )
    return

  drawConcept: (concept, dimensions, radiusScale, labelScale) ->
    radius = radiusScale(concept.phi)
    position =
      x: concept[dimensions[0].direction].repertoire[dimensions[0].index]
      y: concept[dimensions[1].direction].repertoire[dimensions[1].index]
      z: concept[dimensions[2].direction].repertoire[dimensions[2].index]
    star = utils.drawStar(scene, radius, position)

    labelText = globalUtils.formatNodes(concept.mechanism)
      .replace(/\ /g, '')
    labelSize = labelScale(concept.phi)
    label = new Label(
      star, labelText, labelSize,
      @camera, @controls, @renderer
    )
    label.setOffsetFunction (star) ->
      offsetVector = new THREE.Vector3(
        star.position.x,
        star.position.y,
        star.position.z
      )
      offsetVector.add(new THREE.Vector3(0, radius, 0))
      return offsetVector

    # Keep track of the star and label we just made so we can clear them later.
    @constellation.push(star)
    @labels.push(label)
    return

  updateLabels: ->
    for label in @labels
      label.update()
    return

  clearLabels: ->
    for label in @labels
      label.remove()
    @labels = []
    return

  clearConstellation: ->
    for concept in @constellation
      scene.remove(concept)
    @constellation = []
    return

  clearIgnoredAxes: ->
    for axis in @ignoredAxes
      scene.remove(axis)
    @ignoredAxes = []
    return

  clear: ->
    @clearConstellation()
    @clearIgnoredAxes()
    @clearLabels()
    return

  toggleGrids: ->
    for grid in @grids
      grid.visible = not grid.visible
    return

  resetControls: ->
    @controls.reset()
    @controls.target = @scene.position
    return

  render: =>
    @updateLabels()
    @renderer.render(@scene, @camera)
    return

  display: (bigMip) ->
    @clear()
    numNodes = bigMip.subsystem.node_indices.length
    numStates = Math.pow(2, numNodes)
    # Find the three dimensions with the highest variance in probabilities.
    renderedDimensions = getRenderedDimensions(
      bigMip.unpartitioned_constellation, numNodes)
    # Small phi is bounded by n/2
    smallPhiBound = numNodes / 2
    # Get a scale for concept radii
    radiusScale = d3.scale.linear()
      .domain [0, smallPhiBound]
      .range [0, MAX_CONCEPT_RADIUS]
    # Get a scale for concept labels
    labelScale = d3.scale.linear()
      .domain [0, smallPhiBound]
      .range [MIN_CONCEPT_LABEL_SIZE, MAX_CONCEPT_LABEL_SIZE]
    # Draw the unpartitioned constellation.
    for concept in bigMip.unpartitioned_constellation
      @drawConcept(concept, renderedDimensions, radiusScale, labelScale)
    # Draw the ignored axes.
    @drawIgnoredAxes(numStates, renderedDimensions)
    @render()
    return

  toggleIgnoredAxes: ->
    for axis in @ignoredAxes
      axis.visible = not axis.visible


module.exports = JoinedView
