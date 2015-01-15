###
# graph-editor/index.coffee
###

colors = require '../colors'
utils = require './utils'


NETWORK_SIZE_LIMIT = 8
CONTAINER_SELECTOR = '#graph-editor-container'

$container = $(CONTAINER_SELECTOR)
height = 500
width = $container.width()

NODE_RADIUS = 24


# Globals
# =====================================================================

# Declare the canvas.
svg = d3.select CONTAINER_SELECTOR
  .append 'svg'
    .attr 'width', width
    .attr 'height', height
    .attr 'align', 'center'

# Dynamically resize SVG canvas width.
resizeCanvas = ->
  # Update gloval width reference
  width = $container.width()
  # Update SVG dimensions
  svg.attr 'width', width
  # Update force layout dimensions
  force.size [width, height]
  # Redraw graph
  update()

# Define arrow markers for graph links.
svg
  .append 'svg:defs'
  .append 'svg:marker'
    .attr 'id', 'end-arrow'
    .attr 'viewBox', '0 -5 10 10'
    .attr 'refX', 6
    .attr 'markerWidth', 3
    .attr 'markerHeight', 3
    .attr 'orient', 'auto'
  .append 'svg:path'
    .attr 'd', 'M0,-5L10,0L0,5'
    .attr 'fill', colors.link.endpoint
    .classed 'arrow-head', true

svg
  .append 'svg:defs'
  .append 'svg:marker'
    .attr 'id', 'start-arrow'
    .attr 'viewBox', '0 -5 10 10'
    .attr 'refX', 4
    .attr 'markerWidth', 3
    .attr 'markerHeight', 3
    .attr 'orient', 'auto'
  .append 'svg:path'
    .attr 'd', 'M10,-5L0,0L10,5'
    .attr 'fill', colors.link.endpoint
    .classed 'arrow-head', true

# Line displayed when dragging new nodes.
drag_line = svg
  .append 'svg:path'
    .attr 'class', 'link dragline hidden'
    .attr 'stroke', colors.link.line
    .attr 'd', 'M0,0L0,0'

# Handles to link and node element groups.
path = svg
  .append 'svg:g'
    .selectAll 'path'
circleGroup = svg
  .append 'svg:g'
    .selectAll 'g'

selected_node = null
selected_link = null
mouseover_link = null
mousedown_link = null
mouseover_node = null
mousedown_node = null
mouseup_node = null
drag_source = null

absorbNextMouseout = false

# Mouse event vars
resetMouseVars = ->
  mousedown_node = null
  mousedown_link = null
  return

# =====================================================================
# Update force layout (called automatically each iteration).
# =====================================================================
tick = ->
  # Draw directed edges with proper padding from node centers.
  path.attr "d", (edge) ->
    deltaX = edge.target.x - edge.source.x
    deltaY = edge.target.y - edge.source.y
    dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
    normX = deltaX / dist
    normY = deltaY / dist
    sourcePadding = (if edge.bidirectional then NODE_RADIUS + 5 else NODE_RADIUS)
    targetPadding = NODE_RADIUS + 5
    sourceX = edge.source.x + (sourcePadding * normX)
    sourceY = edge.source.y + (sourcePadding * normY)
    targetX = edge.target.x - (targetPadding * normX)
    targetY = edge.target.y - (targetPadding * normY)
    return "M#{sourceX},#{sourceY}L#{targetX},#{targetY}"
  circleGroup.attr 'transform', (node) ->
    "translate(#{node.x},#{node.y})"
  return
# =====================================================================

# Update graph (called when needed).
# =====================================================================
update = ->

  # Update the node and edge list
  nodes = graph.getNodes()
  links = graph.getDrawableEdges()


  # Bind newly-fetched links to path selection.
  path = path.data(links)
  # Update existing links.
  path
      .classed 'selected', (edge) ->
        graph.isSameLink(edge.key, selected_link)
      .style 'marker-start', (edge) ->
        (if edge.bidirectional then 'url(#start-arrow)' else "")
      .style 'marker-end', (edge) ->
        'url(#end-arrow)'
  # Add new links.
  path.enter()
    .append 'svg:path'
      .attr 'class', 'link'
      .attr 'stroke', colors.link.line
      .classed 'selected', (edge) ->
        graph.isSameLink(edge.key, selected_link)
      .style 'marker-start', (edge) ->
        (if edge.bidirectional then 'url(#start-arrow)' else '')
      .style 'marker-end', (edge) ->
        'url(#end-arrow)'
      .on 'mouseover', (edge) ->
        mouseover_link = edge.key
        # Only select link if it's different and we're dragging a new one.
        unless mousedown_node or graph.isSameLink(mouseover_link, selected_link)
          selected_link = mouseover_link
          selected_node = null
          update()
      .on 'mouseout', (edge) ->
        mouseover_link = null
      .on 'mousedown', (edge) ->
        mousedown_link = edge.key
        # Only update mousedown link if it's selected.
        if graph.isSameLink(mousedown_link, selected_link)
          ids = selected_link.split ','
          sourceId = ids[0]
          targetId = ids[1]
          cycleDirection(sourceId, targetId)
          update()
  # Remove old links.
  path.exit().remove()

  # Bind newly-fetched nodes to circle selection.
  # NB: Nodes are known by the graph's internal ID, not by d3 index!
  circleGroup = circleGroup.data nodes, (d) -> d._id

  # Add new nodes.
  g = circleGroup.enter()
    .append 'svg:g'

  g.append 'svg:circle'
      .attr 'class', 'node'
      .attr 'r', NODE_RADIUS
      .classed 'reflexive', (node) ->
        node.reflexive
      .on 'click', (node) ->
        # Don't toggle state if we're dragging a new link or if shift is pressed.
        unless drag_source or d3.event.shiftKey
          graph.toggleState node
          update()
      .on 'mouseover', (node) ->
        # Only select a node if it's a new one and we haven't just finished
        # dragging a new link.
        unless mousedown_node or node is mouseup_node
          # Select node.
          selected_node = node
          selected_link = null
          # Enlarge target node.
          d3.select(this).attr 'transform', 'scale(1.1)'
          update()
        # Update global.
        mouseover_node = node
      .on 'mouseout', (node) ->
        if absorbNextMouseout
          absorbNextMouseout = false
          return

        mouseover_node = null
        # If this is the mouseup node, then we just finished dragging a link.
        if node is mouseup_node then mouseup_node = null
        # Mousedown + mouseout means we're dragging.
        if node is mousedown_node
          drag_source = node
        # Otherwise we've just finished dragging.
        else
          drag_source = null
      .on 'mousedown', (node) ->
        mousedown_node = node

        # Reposition drag line.
        drag_line
          .style 'marker-end', 'url(#end-arrow)'
            .classed 'hidden', false
            .attr 'd', "M#{mousedown_node.x},#{mousedown_node.y}L#{mousedown_node.x},#{mousedown_node.y}"

        update()
      .on 'mouseup', (node) ->
        return unless mousedown_node

        mouseup_node = node

        # Needed by FF.
        drag_line
          .classed 'hidden', true
          .style 'marker-end', ''

        # Check for drag-to-self.
        if mouseup_node is mousedown_node
          resetMouseVars()
          return

        drag_source = null

        # Chrome triggers a mouseout after finishing dragging for some
        # reason...
        if utils.isChrome
          absorbNextMouseout = true

        edge = graph.addEdge mousedown_node._id, mouseup_node._id

        if not edge?
          edge = graph.getEdge mousedown_node._id, mouseup_node._id

        # Select new link.
        selected_link = edge.key
        selected_node = null

        update()

  # Show node IDs.
  g.append 'svg:text'
      .attr 'x', 0
      .attr 'y', -4
      .classed 'node-label', true
      .classed 'id', true
      .attr 'fill', colors.node.label

  # Show node mechanisms.
  g.append 'svg:text'
      .attr 'x', 0
      .attr 'y', 12
      .classed 'node-label', true
      .classed 'mechanism', true
      .attr 'fill', colors.node.label

  # Bind the data to the actual circle elements.
  circles = circleGroup.selectAll 'circle'
    .data nodes, (node) -> node._id

  # Update existing nodes.
  # Note: since we appended to the enter selection, this will be applied to the
  # new circle elements we just created.
  circleGroup.selectAll 'circle'
      .style 'fill', (node) ->
        # Brighten the selected node.
        if (node is selected_node)
          return nodeColor(node).brighter(0.5)
        else
          return nodeColor(node)
      .attr 'transform', (node) ->
        # Enlarge the selected node.
        if (node is selected_node)
          return 'scale(1.1)'
      .classed 'reflexive', (node) ->
        # Mark reflexive nodes.
        node.reflexive
  # Update displayed mechanisms and IDs.
  circleGroup.select '.node-label.id'
    .text (node) -> node.label
  circleGroup.select '.node-label.mechanism'
    .text (node) ->
      if node.mechanism is '>' or node.mechanism is '<'
        return "#{node.mechanism} #{node.threshold}"
      else
        return node.mechanism

  # Remove old nodes.
  circleGroup.exit().remove()

  # Rebind the nodes and links to the force layout.
  force
    .nodes nodes
    .links links

  # Set the graph in motion.
  force.start()

# =====================================================================
# Helpers
# =====================================================================

nodeColor = (node) -> (if node.on then colors.node.on else colors.node.off)

cycleDirection = (sourceId, targetId) ->
  # Cycle through link directions:
  # Original -> reverse
  if (graph.getEdge(sourceId, targetId) and
      not graph.getEdge(targetId, sourceId))
    graph.removeEdge sourceId, targetId
    graph.addEdge targetId, sourceId
  # Reverse -> bidirectional
  else if (graph.getEdge(targetId, sourceId) and
           not graph.getEdge(sourceId, targetId))
    graph.addEdge sourceId, targetId
  # Bidirectional -> original
  else if (graph.getEdge(sourceId, targetId) and
           graph.getEdge(targetId, sourceId))
    graph.removeEdge targetId, sourceId

# =====================================================================
# Mouse handlers
# =====================================================================

dblclick = (e) ->
  return if d3.event.shiftKey or
            mouseover_node or
            mousedown_node or
            mouseover_link or
            graph.nodeSize >= NETWORK_SIZE_LIMIT
  # Prevent I-bar on drag.
  d3.event.preventDefault()
  # Because :active only works in WebKit?
  svg.classed 'active', true
  # Insert new node at this point.
  point = d3.mouse(this)
  # Add the node and start with it selected.
  selected_node = graph.addNode
    x: point[0]
    y: point[1]
  update()


mousemove = ->
  return unless mousedown_node
  # Update drag line.
  drag_line.attr 'd', "M#{mousedown_node.x},#{mousedown_node.y}L#{d3.mouse(this)[0]},#{d3.mouse(this)[1]}"
  update()


mouseup = ->
  # Reset drag source since we're done dragging.
  drag_source = null
  if mousedown_node
    # Hide drag line.
    drag_line
      .classed 'hidden', true
      .style 'marker-end', ''
  # Because :active only works in WebKit?
  svg.classed 'active', false
  # Clear mouse event variables.
  resetMouseVars()


mousedown = ->
  selected_node = null unless mousedown_node
  selected_link = null unless mousedown_link
  update()


# =====================================================================


# Keyboard handlers.
# =====================================================================

# Only respond once per keydown.
lastKeyDown = -1


logChange = (node, propertyName, property) ->
  console.log "Changed node #{selected_node.label} #{propertyName} to " +
              "#{selected_node[property]}."


keydown = ->

  switch d3.event.keyCode
    # Left arrow.
    when 37
      selectPreviousNode()
      update()
      break
    # Up arrow.
    when 38
      selectPreviousNode()
      update()
      break
    # Right arrow.
    when 39
      selectNextNode()
      update()
      break
    # Down arrow.
    when 40
      selectNextNode()
      update()
      break

  return unless lastKeyDown is -1
  lastKeyDown = d3.event.keyCode

  # shift
  if d3.event.keyCode is 16
    circleGroup.call force.drag

  return if not selected_node and not selected_link

  # Node or link is selected:
  # Grab selected link source and target ids.
  if selected_link
    ids = selected_link.split ','
    sourceId = ids[0]
    targetId = ids[1]
  switch d3.event.keyCode
    # backspace, delete
    when 8, 46
      d3.event.preventDefault()
      if selected_node
        removed = graph.removeNode selected_node._id
        selectPreviousNode()
        update()
      else if selected_link
        graph.removeEdge sourceId, targetId
        graph.removeEdge targetId, sourceId
        selected_link = null
        update()
      break
    # d
    when 68
      if selected_link
        cycleDirection(sourceId, targetId)
        update()
      break
    # b
    when 66
      if selected_link
        graph.addEdge sourceId, targetId
        graph.addEdge targetId, sourceId
        update()
      break
    # space
    when 32
      d3.event.preventDefault()
      if selected_node
        graph.toggleState selected_node
        logChange(selected_node, 'state', 'on')
        update()
      break
    # m
    when 77
      if selected_node
        graph.cycleMechanism selected_node
        logChange(selected_node, 'mechanism', 'mechanism')
        update()
      break
    when 84
      if selected_node
        if selected_node.threshold >= NETWORK_SIZE_LIMIT
          newThreshold = 0
        else
          newThreshold = selected_node.threshold + 1
        graph.setThreshold selected_node, newThreshold
        logChange(selected_node, 'threshold', 'threshold')
        update()
      break
    # r
    when 82
      if selected_node
        graph.toggleReflexivity selected_node
        logChange(selected_node, 'reflexivity', 'reflexive')
        update()
      break
    # f
    when 70
      if selected_node
        # Free/fix node
        selected_node.fixed = not selected_node.fixed
        update()


selectNextNode = ->
  if not selected_node or selected_node.index is graph.nodeSize - 1
    selected_node = graph.getNodeByIndex 0
  else
    selected_node = graph.getNodeByIndex(selected_node.index + 1)
  selected_link = null


selectPreviousNode = ->
  if not selected_node or selected_node.index is 0
    selected_node = graph.getNodeByIndex(graph.nodeSize - 1)
  else
    selected_node = graph.getNodeByIndex(selected_node.index - 1)
  selected_link = null


keyup = ->
  lastKeyDown = -1
  # Stop dragging when shift is released.
  if d3.event.keyCode is 16
    circleGroup
        .on 'mousedown.drag', null
        .on 'touchstart.drag', null
    svg.classed('shiftkey', false)


nearestNeighbor = (node, nodes) ->
  nearest = selected_node
  minDistance = Infinity
  for n in nodes
    d = dist [node.x, node.y], [n.x, n.y]
    if d <= minDistance
      minDistance = d
      nearest = n
  return nearest


dist = (p0, p1) ->
  Math.sqrt(Math.pow(p1[0] - p0[0], 2) + Math.pow(p1[1] - p0[1], 2))



# Initialization
# =============================================================================

examples = require './examples'
graph = examples.paper()
# graph = examples.chain 3,
#   circle: false
#   reflexive: false
#   bidirectional: false

# Resize canvas.
$(window).resize resizeCanvas
# Bind d3 nodes and links to graph.
nodes = graph.getNodes()
links = graph.getDrawableEdges()
# Initialize D3 force layout.
force = d3.layout.force()
    .nodes nodes
    .links links
    .size [width, height]
    .linkDistance 175
    .linkStrength 0.75
    .charge -900
    .on 'tick', tick

# Bind drag handler.
drag = force.drag()
  .on 'dragstart', (node) -> node.fixed = true

# Bind global mouse handlers.
svg
    .on 'dblclick', dblclick
    .on 'mousemove', mousemove
    .on 'mousedown', mousedown
    .on 'mouseup', mouseup
# Bind global keyboard handlers.
d3.select document
    .on 'keydown', keydown
    .on 'keyup', keyup
# Go go go!
update()

# =============================================================================


exports.graph = graph
