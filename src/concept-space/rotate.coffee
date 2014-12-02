# Rotate an object around an arbitrary axis in world space
exports.aroundWorldAxis = (object, axis, radians) ->
  rotWorldMatrix = new THREE.Matrix4()
  rotWorldMatrix.makeRotationAxis(axis.normalize(), radians)

  rotWorldMatrix.multiply(object.matrix)
  object.matrix = rotWorldMatrix

  object.rotation.setFromRotationMatrix(object.matrix)
  return

# Rotate an object around an arbitrary axis in object space
exports.aroundObjectAxis = (object, axis, radians) ->
  rotObjectMatrix = new THREE.Matrix4()
  rotObjectMatrix.makeRotationAxis(axis.normalize(), radians)

  object.matrix.multiply(rotObjectMatrix)

  object.rotation.setFromRotationMatrix(object.matrix)
  return
