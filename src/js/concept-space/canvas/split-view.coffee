###
# concept-space/split-view.coffee
#
# Returns a scene initialized with all the static stuff necessary to represent
# concept space.
###

axes = require './axes'
utils = require './utils'


π = Math.PI
MAX_CONCEPT_RADIUS = 0.5

scene = new THREE.Scene()

currentConstellation = []
currentIgnoredAxes = []


getRenderedDimensions = (constellation, numNodes) ->
  numStates = Math.pow(2, numNodes)
  # Past
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  pastDistributions = (c.cause.repertoire for c in constellation)
  futureDistributions = (c.effect.repertoire for c in constellation)
  return {
    past: utils.sortStatesByVariance(pastDistributions, numStates)[-3...]
    future: utils.sortStatesByVariance(futureDistributions, numStates)[-3...]
  }


getConceptRadius = (numNodes, phi) -> (phi / numNodes) * MAX_CONCEPT_RADIUS


drawConcept = (concept, renderedDimensions, numNodes) ->
  radius = getConceptRadius(numNodes, concept.phi)
  # Past
  position =
    x: concept.cause.repertoire[renderedDimensions.past[0]]
    y: concept.cause.repertoire[renderedDimensions.past[1]]
    z: concept.cause.repertoire[renderedDimensions.past[2]]
  pastConcept = utils.drawStar(scene, radius, position)
  # Future
  position =
    x: - concept.effect.repertoire[renderedDimensions.future[0]]
    y: - concept.effect.repertoire[renderedDimensions.future[1]]
    z: - concept.effect.repertoire[renderedDimensions.future[2]]
  futureConcept = utils.drawStar(scene, radius, position)
  return [pastConcept, futureConcept]


clearConstellation = ->
  for concept in currentConstellation
    scene.remove(concept)
  currentConstellation = []


clearIgnoredAxes = ->
  for axis in currentIgnoredAxes
    scene.remove(axis)
  currentIgnoredAxes = []


clear = ->
  clearConstellation()
  clearIgnoredAxes()


class SplitView
  constructor: (@container, width, height) ->

    @scene = scene

    # ~~~~~~~~~
    # Lighting.
    # ~~~~~~~~~
    @scene.add(new THREE.AmbientLight(0x999999))
    future_light = new THREE.PointLight(0xffffff, 1, 0)
    future_light.position.set(2, 2, 2)
    @scene.add(future_light)
    past_light = new THREE.PointLight(0xffffff, 1, 0)
    past_light.position.set(-2, -2, -2)
    @scene.add(past_light)
    @scene.add(new THREE.HemisphereLight(0xdddddd, 0x444444))
    # ~~~~~~~~~

    # Draw the past and future axes.
    axes.drawSplit(@scene)

    # ~~~~~~~~~~~~~~~~~~~~
    # Draw the axis grids.
    # ~~~~~~~~~~~~~~~~~~~~
    gridStep = 0.2
    # XY
    xyPastGrid = new THREE.GridHelper(0.5, gridStep)
    xyPastGrid.rotation.set(π/2, 0, 0)
    xyPastGrid.position.set(-0.5, -0.5, -0.0)
    xyFutureGrid = new THREE.GridHelper(0.5, 0.2)
    xyFutureGrid.rotation.set(π/2, 0, 0)
    xyFutureGrid.position.set(0.5, 0.5, 0.0)
    # YZ
    yzPastGrid = new THREE.GridHelper(0.5, gridStep)
    yzPastGrid.rotation.set(0, π/2, 0)
    yzPastGrid.position.set(-0.5, -0.0, -0.5)
    yzFutureGrid = new THREE.GridHelper(0.5, gridStep)
    yzFutureGrid.rotation.set(0, π/2, 0)
    yzFutureGrid.position.set(0.5, 0.0, 0.5)
    # ZX
    zxPastGrid = new THREE.GridHelper(0.5, gridStep)
    zxPastGrid.rotation.set(0, 0, π/2)
    zxPastGrid.position.set(-0.0, -0.5, -0.5)
    zxFutureGrid = new THREE.GridHelper(0.5, gridStep)
    zxFutureGrid.rotation.set(0, 0, π/2)
    zxFutureGrid.position.set(0.0, 0.5, 0.5)

    @grids = [
      xyPastGrid, xyFutureGrid, yzPastGrid, yzFutureGrid,
      zxPastGrid, zxFutureGrid
    ]

    for grid in @grids
      @scene.add(grid)
    # ~~~~~~~~~~~~~~~~~~~~

    # Initialize the camera.
    @camera = new THREE.PerspectiveCamera(20, width / height, 0.01, 1000)
    @scene.add(@camera)
    @camera.position.set(-4, 5, 3)

    # Initialize the camera controls.
    @controls = new THREE.TrackballControls(@camera, @container)

    @controls.rotateSpeed = 2.0
    @controls.zoomSpeed = 3
    @controls.panSpeed = 1.0

    @controls.noRotate = false
    @controls.noZoom = false
    @controls.noPan = false

    @controls.staticMoving = true
    @controls.dynamicDampingFactor = 0.15

    @controls.addEventListener('change', @render)

    # Initialize the renderer.
    @renderer = new THREE.WebGLRenderer(alpha: false)
    @renderer.setSize(width, height)

    @resetControls()

  toggleGrids: =>
    for grid in @grids
      grid.visible = not grid.visible

  resetControls: =>
    @controls.reset()
    @controls.target = @scene.position

  render: =>
    @renderer.render(@scene, @camera)

  animate: =>
    requestAnimationFrame(@animate)
    @render()
    @controls.update()

  display: (bigMip) =>
    clear()
    numNodes = bigMip.subsystem.node.length
    numStates = Math.pow(2, numNodes)
    # Find the three dimensions with the highest variance in probabilities.
    renderedDimensions = getRenderedDimensions(bigMip.ces.concepts, numNodes)
    # Draw the unpartitioned constellation.
    for concept in bigMip.ces.concepts
      currentConstellation = currentConstellation.concat(
        drawConcept(concept, renderedDimensions, numNodes)
      )
    # Draw the ignored axes.
    currentIgnoredAxes = currentIgnoredAxes.concat(
      axes.drawSplitIgnored(@scene, numStates - 3, 'past', renderedDimensions)
    )
    currentIgnoredAxes = currentIgnoredAxes.concat(
      axes.drawSplitIgnored(@scene, numStates - 3, 'future', renderedDimensions)
    )

  toggleIgnoredAxes: =>
    for axis in currentIgnoredAxes
      axis.visible = not axis.visible


module.exports = SplitView
