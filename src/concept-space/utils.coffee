_ = require 'jashkenas/underscore'

sum = (x) ->
  x.reduce (a, b) -> a + b

mean = (x) ->
  if x.length is 0 then return null
  return sum(x) / x.length

variance = (x) ->
  if x.length is 0 then return null
  mean_value = mean(x)
  deviations = (Math.pow(n - mean_value, 2) for n in x)
  return mean(deviations)

module.exports =

  sortStatesByVariance: (distributions, numStates) ->
    probabilities = ((d[i] for d in distributions) for i in [0...numStates])
    variances = ({
        state: i
        variance: variance(probabilities[i])
      } for i in [0...numStates]
    )
    # (b - a) => descending sort.
    variances = _.sortBy(variances, 'variance')
    return (v.state for v in variances)

  drawStar: (scene, radius, position) ->
    # TODO make these actual stars.
    # material = new THREE.MeshPhongMaterial(
    #   wireframe: false
    #   ambient: 0x404040
    #   color: 0xF5F237
    #   specular: 0x404040
    #   shininess: 20
    #   shading: THREE.SmoothShading
    #   transparent: true
    # )
    material = new THREE.MeshNormalMaterial(
      wireframe: true
      wireframeLinewidth: 3
      shading: THREE.SmoothShading
    )
    geometry = new THREE.SphereGeometry(radius, 1, 1)
    star = new THREE.Mesh(geometry, material)
    star.position.set(position.x, position.y, position.z)
    scene.add(star)
    return star
