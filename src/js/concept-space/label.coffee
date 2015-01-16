###
# concept-space/label.coffee
#
# A DOM-element label for a THREE.js object.
###

class Label
  constructor: (@object, content, size, @camera, controls, @renderer) ->
    @offset = (object) -> object.position

    @label = $("<div>#{content}</div>")
      .insertAfter(@renderer.domElement)
    @label.addClass('threejs-label')
    @label.css('font-size', size)

    @width = @label.outerWidth()
    @height = @label.outerHeight()

    # Bind control event handlers to the label, so it's treated as part of the
    # scene even though it's a sibling DOM element.
    controls.bindEventHandlers(@label[0])

    @update()

  setOffsetFunction: (offsetFunction) -> @offset = offsetFunction

  setScaleFunction: (scaleFunction) -> @scale = setScaleFunction

  get2Dpoint: (position) ->
    vector = new THREE.Vector3(position.x, position.y, position.z)
      .project(@camera)
    halfHeight = @renderer.domElement.height / 2
    halfWidth = @renderer.domElement.width / 2
    return {
      x: Math.round(vector.x * halfWidth + halfWidth)
      y: Math.round(- vector.y * halfHeight + halfHeight)
    }

  inBounds: (coord) ->
    coord.y > 0 and
    coord.x > 0 and
    coord.y + @height < @renderer.domElement.height and
    coord.x + @width < @renderer.domElement.width

  update: ->
    coord = @get2Dpoint(@offset(@object))
    if @inBounds(coord)
      # Show and update coords
      @label.css
        'top': coord.y + 'px'
        'left': coord.x + 'px'
        'display': 'block'
    else
      # Hide using display property
      # See http://jsperf.com/fastest-way-to-hide-dom-element/
      @label.css('display', 'none')
    return

module.exports = Label
