###
# concept-space/utils.coffee
###

variance = (x) ->
  if x.length is 0 then return null
  deviations = (Math.pow(n - d3.mean(x), 2) for n in x)
  return d3.mean(deviations)

module.exports =

  sortStatesByVariance: (distributions, numStates) ->
    probabilities = ((d[i] for d in distributions) for i in [0...numStates])
    variances = ({
        state: i
        variance: variance(probabilities[i])
      } for i in [0...numStates]
    )
    # Ascending sort.
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
    geometry = new THREE.SphereGeometry(radius, 2, 2)
    star = new THREE.Mesh(geometry, material)
    star.position.set(position.x, position.y, position.z)
    scene.add(star)
    return star
