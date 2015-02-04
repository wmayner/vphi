###
# concept-space/utils.coffee
###

variance = (x) ->
  if x.length is 0 then return null
  deviations = (Math.pow(n - d3.mean(x), 2) for n in x)
  return d3.mean(deviations)

module.exports =

  sortByVariance: (probabilities, numStates) ->
    variances = ({
        index: index
        variance: variance(dimension)
      } for dimension, index in probabilities
    )
    # Descending sort.
    return (v.index for v in _.sortBy(variances, (d) -> - d.variance))

  drawStar: (scene, radius, position) ->
    # TODO make these actual stars.
    material = new THREE.MeshPhongMaterial(
      transparent: true
      opacity: 0.9
      # wireframe: true
      # wireframeLinewidth: 2
      ambient: 0x404040
      color: 0xF5F237
      specular: 0x404040
      shininess: 3
      shading: THREE.SmoothShading
      # Necessary for nested transparent objects to render properly.
      depthWrite: false
    )
    # material = new THREE.MeshNormalMaterial(
    #   wireframe: true
    #   wireframeLinewidth: 3
    #   shading: THREE.SmoothShading
    # )
    geometry = new THREE.SphereGeometry(radius, 32, 32)
    star = new THREE.Mesh(geometry, material)
    star.position.set(position.x, position.y, position.z)
    scene.add(star)
    return star
