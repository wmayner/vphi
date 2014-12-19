###
# concept-space/joined-view.coffee
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
  pastDistributions = (c.cause.repertoire for c in constellation)
  futureDistributions = (c.effect.repertoire for c in constellation)
  distributions = pastDistributions.concat(futureDistributions)
  renderedDimensions = utils.sortStatesByVariance( \
      distributions, (2 * numStates))[0...3]
  renderedDimensions = ({
    direction: (if d >= numStates then 'effect' else 'cause')
    index: (if d >= numStates then d - numStates else d)
  } for d in renderedDimensions)
  return renderedDimensions

getConceptRadius = (numNodes, phi) -> (phi / numNodes) * MAX_CONCEPT_RADIUS


drawConcept = (concept, dimensions, numNodes) ->
  radius = getConceptRadius(numNodes, concept.phi)
  position =
    x: concept[dimensions[0].direction].repertoire[dimensions[0].index]
    y: concept[dimensions[1].direction].repertoire[dimensions[1].index]
    z: concept[dimensions[2].direction].repertoire[dimensions[2].index]
  utils.drawStar(scene, radius, position)


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


class JoinedView
  constructor: (@container, width, height) ->

    @scene = scene

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

    # Initialize the camera.
    @camera = new THREE.PerspectiveCamera(20, width / height, 0.01, 1000)
    @scene.add(@camera)
    @camera.position.set(4, 4, 4)

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

    # Start with the default focal point and camera position.
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
    numNodes = bigMip.subsystem.node_indices.length
    numStates = Math.pow(2, numNodes)
    # Find the three dimensions with the highest variance in probabilities.
    renderedDimensions = getRenderedDimensions(
      bigMip.unpartitioned_constellation, numNodes)
    # Draw the unpartitioned constellation.
    for concept in bigMip.unpartitioned_constellation
      currentIgnoredAxes = currentIgnoredAxes.concat(
        drawConcept(concept, renderedDimensions, numNodes)
      )
    # Draw the ignored axes.
    currentIgnoredAxes = currentIgnoredAxes.concat(
      axes.drawJoinedIgnored(scene, numStates - 3, renderedDimensions)
    )


module.exports = JoinedView
