###
# graph-editor/index.coffee
###

colors = require '../colors'
utils = require './utils'


NETWORK_SIZE_LIMIT = 10
CONTAINER_SELECTOR = '#graph-editor-container'

$container = $(CONTAINER_SELECTOR)
height = 500
width = $container.width()

NODE_RADIUS = 25
REFLEXIVE_NODE_BORDER = 4.5
SUBSYSTEM_MARKER_BORDER = 8

# New nodes will be connected to neighbors within this radius.
NEIGHBOR_RADIUS = 75
# The radius within which to ignore dragging.
IGNORE_DRAG_THRESHOLD = 10


# Globals
# =====================================================================

# Declare the canvas.
svg = d3.select CONTAINER_SELECTOR
  .append 'svg'
    .attr
      width: width
      height: height
      align: 'center'

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
  return

# Draggable node selection box
drag_rect = svg
  .append 'svg:rect'
    .attr
      class: 'selection-box hidden'
      x: 0
      y: 0
      width: 0
      height: 0
selection_box_visible = false

# Line displayed when dragging new nodes.
drag_line = svg
  .append 'svg:path'
    .attr
      class: 'link dragline hidden'
      stroke: colors.link.line
      d: 'M0,0L0,0'

# Circle indicating radius within which new nodes will form connections.
neighborCircle = svg
  .append('svg:circle')
    .attr
      class: 'neighbor-circle hidden'
      r: NEIGHBOR_RADIUS
# Only display the circle when the mouse is on the canvas.
svg
  .on 'mouseover', ->
    neighborCircle.classed 'hidden', false
  .on 'mouseout', ->
    neighborCircle.classed 'hidden', true

# Handles to link and node element groups.
path = svg
  .append 'svg:g'
    .selectAll 'path'
circleGroup = svg
  .append 'svg:g'
    .selectAll 'g'

# Define arrow markers for graph links.
svg
  .append 'svg:defs'
  .append 'svg:marker'
    .attr
      id: 'end-arrow'
      viewBox: '0 -5 10 10'
      refX: 6
      markerWidth: 3
      markerHeight: 3
      orient: 'auto'
  .append 'svg:path'
    .attr
      d: 'M0,-5L10,0L0,5'
      fill: colors.link.endpoint
      class: 'arrow-head'

svg
  .append 'svg:defs'
  .append 'svg:marker'
    .attr
      id: 'start-arrow'
      viewBox: '0 -5 10 10'
      refX: 4
      markerWidth: 3
      markerHeight: 3
      orient: 'auto'
  .append 'svg:path'
    .attr
      d: 'M10,-5L0,0L10,5'
      fill: colors.link.endpoint
      class: 'arrow-head'


focused_node = null
focused_link = null
mousedown_point = null
mouseover_link = null
mousedown_link = null
mouseover_node = null
mousedown_node = null
mouseup_node = null
drag_source = null
selected_nodes = []

absorbNextMouseout = false

# Mouse event vars.
resetMouseVars = ->
  mousedown_node = null
  mousedown_link = null
  return


# Helpers
# =====================================================================

nodeColor = (node) -> (if node.on then colors.node.on else colors.node.off)

focusNode = (node) ->
  focused_node = node
  focused_link = null

focusLink = (link) ->
  focused_link = link
  focused_node = null

selectNode = (node) ->
  # Add node to selected node list.
  selected_nodes.push node
  # Mark it as selected.
  node.selected = true

deselectNode = (node) ->
  # Remove node from selected node list.
  selected_nodes.splice selected_nodes.indexOf(node), 1
  # Mark it as not selected.
  node.selected = false

deltaDistance = (dx, dy) ->
  Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))

distance = (p1, p2) ->
  dx = p2[0] - p1[0]
  dy = p2[1] - p1[1]
  deltaDistance(dx, dy)

getRadius = (node) ->
  r = NODE_RADIUS
  if node.reflexive
    r += REFLEXIVE_NODE_BORDER
  if node is focused_node
    r += NODE_RADIUS * 0.1
  return r

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

focusNextNode = ->
  if not focused_node or focused_node.index is graph.nodeSize - 1
    focusNode(graph.getNodeByIndex 0)
  else
    focusNode(graph.getNodeByIndex(focused_node.index + 1))

focusPreviousNode = ->
  if not focused_node or focused_node.index is 0
    focusNode(graph.getNodeByIndex(graph.nodeSize - 1))
  else
    focusNode(graph.getNodeByIndex(focused_node.index - 1))

nearestNeighbor = (node, nodes) ->
  nearest = focused_node
  minDistance = Infinity
  for n in nodes
    d = distance [node.x, node.y], [n.x, n.y]
    if d <= minDistance
      minDistance = d
      nearest = n
  return nearest

# Update force layout (called automatically each iteration).
# =====================================================================
tick = ->
  # Draw directed edges with proper padding from node centers.
  path.attr "d", (edge) ->
    dx = edge.target.x - edge.source.x
    dy = edge.target.y - edge.source.y
    dist = deltaDistance dx, dy
    normX = dx / dist
    normY = dy / dist

    # Draw the line to the edge of the circle, not the center.
    sourcePadding = getRadius(edge.source)
    targetPadding = getRadius(edge.target)

    # Paddding for arrowheads.
    targetPadding += 5
    if edge.bidirectional
      sourcePadding += 5

    sourceX = edge.source.x + (sourcePadding * normX)
    sourceY = edge.source.y + (sourcePadding * normY)
    targetX = edge.target.x - (targetPadding * normX)
    targetY = edge.target.y - (targetPadding * normY)
    return "M#{sourceX},#{sourceY}L#{targetX},#{targetY}"
  circleGroup.attr 'transform', (node) ->
    "translate(#{node.x},#{node.y})"
  return


# Update graph (called when needed).
# =====================================================================
update = ->

  # Update the node and edge list.
  nodes = graph.getNodes()
  links = graph.getDrawableEdges()


  # Bind newly-fetched links to path selection.
  path = path.data(links)
  # Update existing links.
  path
      .classed 'focused', (edge) ->
        graph.isSameLink(edge.key, focused_link)
      .style 'marker-start', (edge) ->
        (if edge.bidirectional then 'url(#start-arrow)' else "")
      .style 'marker-end', (edge) ->
        'url(#end-arrow)'
  # Add new links.
  path.enter()
    .append 'svg:path'
      .attr 'class', 'link'
      .attr 'stroke', colors.link.line
      .classed 'focused', (edge) ->
        graph.isSameLink(edge.key, focused_link)
      .style 'marker-start', (edge) ->
        (if edge.bidirectional then 'url(#start-arrow)' else '')
      .style 'marker-end', (edge) ->
        'url(#end-arrow)'
      .on 'mouseover', (edge) ->
        mouseover_link = edge.key
        # Only focus link if it's different and we're dragging a new one, and
        # we're not selecting nodes.
        unless mousedown_node or
               selection_box_visible or
               graph.isSameLink(mouseover_link, focused_link)
          focusLink(mouseover_link)
          update()
        return
      .on 'mouseout', (edge) ->
        mouseover_link = null
      .on 'mousedown', (edge) ->
        mousedown_link = edge.key
        # Only update mousedown link if it's focused.
        if graph.isSameLink(mousedown_link, focused_link)
          ids = focused_link.split ','
          sourceId = ids[0]
          targetId = ids[1]
          cycleDirection(sourceId, targetId)
          update()
        return
  # Remove old links.
  path.exit().remove()

  # Bind newly-fetched nodes to circle selection.
  # NB: Nodes are known by the graph's internal ID, not by d3 index!
  circleGroup = circleGroup.data nodes, (d) -> d._id

  # Add new nodes.
  g = circleGroup.enter()
    .append 'svg:g'

  # Mark nodes in the currently chosen subsystem with dashed circles.
  g.append 'svg:circle'
    .attr 'class', 'subsystem-marker'

  g.append 'svg:circle'
      .attr
        class: 'node'
        r: NODE_RADIUS
      .on 'click', (node) ->
        focusNode(node)
        # Select/deselect node if command is held.
        if d3.event.metaKey
          node.selected = not node.selected
        # Don't toggle state if we're dragging a new link or if shift or command is pressed.
        else unless drag_source or d3.event.shiftKey
          graph.toggleState node
        update()
        return
      .on 'mouseover', (node) ->
        neighborCircle.classed 'hidden', true
        # Only focus a node if it's a new one and we haven't just finished
        # dragging a new link.
        unless mousedown_node or node is mouseup_node
          focusNode(node)
          # Enlarge target node.
          d3.select(this).attr 'transform', 'scale(1.1)'
          update()
        # Update global.
        mouseover_node = node
        return
      .on 'mouseout', (node) ->
        # Show neighbor circle if we're not dragging.
        unless selection_box_visible or d3.event.shiftKey
          neighborCircle.classed 'hidden', false

        mouseover_node = null

        if absorbNextMouseout
          absorbNextMouseout = false
          return

        # If this is the mouseup node, then we just finished dragging a link.
        if node is mouseup_node then mouseup_node = null
        # Mousedown + mouseout means we're dragging.
        if node is mousedown_node
          drag_source = node
        # Otherwise we've just finished dragging.
        else
          drag_source = null

        return
      .on 'mousedown', (node) ->
        mousedown_node = node

        unless d3.event.shiftKey
          # Reposition drag line.
          drag_line
            .style 'marker-end', 'url(#end-arrow)'
            .classed 'hidden', false
            .attr
              d: "M#{mousedown_node.x},#{mousedown_node.y}L#{mousedown_node.x},#{mousedown_node.y}"

        update()
        return
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

        # Focus new link.
        focusLink(edge.key)

        update()
        return

  # Show node IDs.
  g.append 'svg:text'
      .attr
        x: 0
        y: -4
        class: 'node-label id'

  # Show node mechanisms.
  g.append 'svg:text'
      .attr
        x: 0
        y: 12
        class: 'node-label mechanism'

  # Bind the data to the actual circle elements.
  circles = circleGroup.selectAll 'circle.node'
    .data nodes, (node) -> node._id

  # Update existing nodes.
  # Note: since we appended to the enter selection, this will be applied to the
  # new circle elements we just created.
  circleGroup.selectAll 'circle.node'
      .style 'fill', (node) ->
        # Brighten the focused node.
        if (node is focused_node)
          return nodeColor(node).brighter(0.5)
        else
          return nodeColor(node)
      .classed 'on', (node) -> node.on
      .classed 'off', (node) -> not node.on
      .classed 'reflexive', (node) -> node.reflexive
      .attr 'r', (node) ->
        # Strokes are centered on the edge of the shape, so we need to extend
        # the radius by half the desired border width to keep the percieved
        # radius the same.
        r = NODE_RADIUS
        if node.reflexive
          r += REFLEXIVE_NODE_BORDER / 2
        return r
      .attr 'stroke-width', (node) ->
        return (if node.reflexive then REFLEXIVE_NODE_BORDER else 0)
  # Update subsystem inclusion markers.
  circleGroup.select '.subsystem-marker'
    .classed 'hidden', (node) -> not node.selected
    .attr 'r', (node) ->
      r = NODE_RADIUS + SUBSYSTEM_MARKER_BORDER
      if node.reflexive
        r += REFLEXIVE_NODE_BORDER
      return r
  # Enlarge the focused node.
  circleGroup.selectAll 'circle'
      .attr 'transform', (node) ->
        if (node is focused_node)
          return 'scale(1.1)'
  # Update displayed mechanisms and IDs.
  circleGroup.selectAll 'text'
    .style 'fill', (node) -> (if node.on then colors.node.label.on else colors.node.label.off)
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
  return


# Mouse handlers
# =====================================================================

drag = d3.behavior.drag()
  .on 'drag', (d, i) ->
    selection = svg.selectAll ".selected"
    if selection[0].indexOf(this) is -1
      selection.classed "selected", false
      selection = d3.select(this)
      selection.classed "selected", true
circleGroup.call(drag)


dblclick = (e) ->
  point = d3.mouse(this)

  neighbors = []

  d3.selectAll 'circle.node'
    .each (node, i) ->
      dist = distance(point, [node.x, node.y])
      neighbors.push node if dist < NEIGHBOR_RADIUS + getRadius(node)
      return

  dragDistance = 0
  if mousedown_point
    dragDistance = distance(point, mousedown_point)

  # Don't create a new node if we're holding shift, dragging, mousing-over a
  # node or link, or the network size limit has been reached.
  unless d3.event.shiftKey or
         mouseover_node or
         mouseover_link or
         dragDistance > IGNORE_DRAG_THRESHOLD or
         graph.nodeSize >= NETWORK_SIZE_LIMIT
    # Prevent I-bar on drag.
    d3.event.preventDefault()
    # Because :active only works in WebKit?
    svg.attr 'active', true
    # Insert new node
    newNode = graph.addNode
      x: point[0]
      y: point[1]
    # Start with the node focused.
    focusNode(newNode)
    # Add a bidirectional edge to nearby nodes.
    for neighbor in neighbors
      graph.addEdge(newNode._id, neighbor._id)
      graph.addEdge(neighbor._id, newNode._id)
    update()
  return


mousemove = ->
  point = d3.mouse(this)

  if mousedown_node
    # Update drag line.
    drag_line.attr 'd', "M#{mousedown_node.x},#{mousedown_node.y}L#{point[0]},#{point[1]}"
  else
    # Update neighbor circle.
    neighborCircle.attr
      cx: point[0]
      cy: point[1]
    # Hide it if we're mousing over a node or dragging.
    if mouseover_node or
        (mousedown_point and
         distance(point, mousedown_point) > IGNORE_DRAG_THRESHOLD)
      neighborCircle.classed 'hidden', true

    # Update selection box.
    d =
      x: parseInt(drag_rect.attr('x'), 10)
      y: parseInt(drag_rect.attr('y'), 10)
      width: parseInt(drag_rect.attr('width'), 10)
      height: parseInt(drag_rect.attr('height'), 10)

    move =
      x: point[0] - d.x
      y: point[1] - d.y

    if move.x < 1 or (move.x * 2 < d.width)
      d.x = point[0]
      d.width -= move.x
    else
      d.width = move.x

    if move.y < 1 or (move.y * 2 < d.height)
      d.y = point[1]
      d.height -= move.y
    else
      d.height = move.y

    drag_rect.attr d

    if selection_box_visible
      # Select nodes within the selection box.
      d3.selectAll 'circle.node'
        .each (node, i) ->
          radius = getRadius(node)
          nodeInSelectionBox = (
            node.x + radius >= d.x and
            node.x - radius <= d.x + d.width and
            node.y + radius >= d.y and
            node.y - radius <= d.y + d.height
          )
          if nodeInSelectionBox
            unless node.selected
              # Focus and select node.
              focusNode(node)
              selectNode(node)
          else
            if node is focused_node
              # Unfocus node and refocus most recently selected node.
              focusNode(selected_nodes[selected_nodes.length - 1])
            if node.selected
              deselectNode(node)
          return

  update()
  return


mouseup = ->
  # Reset drag source and mousedown point since we're done dragging.
  drag_source = null
  mousedown_point = null
  if mousedown_node
    # Hide drag line.
    drag_line
      .classed 'hidden', true
      .style 'marker-end', ''
  else
    # Hide selection box.
    drag_rect.classed 'hidden', true
    selection_box_visible = false
    unless mouseover_node
      neighborCircle.classed 'hidden', false
  # Because :active only works in WebKit?
  svg.classed 'active', false
  # Clear mouse event variables.
  resetMouseVars()


mousedown = ->
  mousedown_point = d3.mouse(this)

  unless mousedown_link
    # Deselect link.
    focused_link = null

  unless mousedown_node
    # Show selection box and redraw it starting at mouse.
    drag_rect.classed 'hidden', false
    selection_box_visible = true
    focused_node = null
    drag_rect.attr
      x: mousedown_point[0]
      y: mousedown_point[1]
      width: 0
      height: 0

  # Reset selection unless clicking on a node or a link, or holding shift or
  # command.
  unless mousedown_link or
         mousedown_node or
         d3.event.shiftKey or
         d3.event.metaKey
    # Clear selected node list.
    selected_nodes = []
    # Deselect nodes.
    d3.selectAll 'circle.node'
      .each (node, i) ->
        node.selected = false

  update()
  return


# Keyboard handlers.
# =====================================================================

# Only respond once per keydown.
lastKeyDown = -1


logChange = (node, propertyName, property) ->
  log.debug "GRAPH_EDITOR: Set node #{node.label} #{propertyName} to " +
            "#{node[property]}."


keydown = ->

  switch d3.event.keyCode
    # Left arrow.
    when 37
      focusPreviousNode()
      update()
      break
    # Up arrow.
    when 38
      focusPreviousNode()
      update()
      break
    # Right arrow.
    when 39
      focusNextNode()
      update()
      break
    # Down arrow.
    when 40
      focusNextNode()
      update()
      break
    # backspace, delete
    when 8, 46
      # Don't go “back” with backspace/delete (too easy to accidentally lose
      # the page instead of deleting a node).
      d3.event.preventDefault()

  return unless lastKeyDown is -1
  lastKeyDown = d3.event.keyCode

  # shift
  if d3.event.keyCode is 16
    circleGroup.call force.drag

  return if not focused_node and not focused_link

  # Node or link is focused:
  # Grab focused link source and target ids.
  if focused_link
    ids = focused_link.split ','
    sourceId = ids[0]
    targetId = ids[1]
  switch d3.event.keyCode
    # backspace, delete, d
    when 8, 46, 68
      if selected_nodes.length > 0
        for node in selected_nodes
          removed = graph.removeNode node._id
          focusPreviousNode()
        update()
      else if focused_node
        removed = graph.removeNode focused_node._id
        focusPreviousNode()
        update()
      else if focused_link
        graph.removeEdge sourceId, targetId
        graph.removeEdge targetId, sourceId
        focused_link = null
        update()
      break
    # c
    when 67
      if focused_link
        cycleDirection(sourceId, targetId)
        update()
      break
    # b
    when 66
      if focused_link
        graph.addEdge sourceId, targetId
        graph.addEdge targetId, sourceId
        update()
      break
    # space
    when 32
      d3.event.preventDefault()
      if selected_nodes.length > 0
        graph.toggleStates selected_nodes
        for node in selected_nodes
          logChange(node, 'state', 'on')
        update()
      else if focused_node
        graph.toggleState focused_node
        logChange(focused_node, 'state', 'on')
        update()
      break
    # m
    when 77
      if selected_nodes.length > 0
        graph.cycleMechanisms selected_nodes
        for node in selected_nodes
          logChange(node, 'state', 'on')
        update()
      else if focused_node
        graph.cycleMechanism focused_node
        logChange(focused_node, 'mechanism', 'mechanism')
        update()
      break
    # t
    when 84
      if focused_node
        if focused_node.threshold >= NETWORK_SIZE_LIMIT
          newThreshold = 0
        else
          newThreshold = focused_node.threshold + 1
        graph.setThreshold focused_node, newThreshold
        logChange(focused_node, 'threshold', 'threshold')
        update()
      break
    # r
    when 82
      if selected_nodes.length > 0
        graph.toggleSelfLoops selected_nodes
        for node in selected_nodes
          logChange(node, 'reflexivity', 'reflexive')
        update()
      else if focused_node
        graph.toggleSelfLoop focused_node
        logChange(focused_node, 'reflexivity', 'reflexive')
        update()
      break
    # f
    when 70
      if selected_nodes.length > 0
        initial = selected_nodes[0].fixed
        for node in selected_nodes
          node.fixed = not initial
          logChange(node, 'fixed', 'fixed')
        update()
      else if focused_node
        # Free/fix node
        focused_node.fixed = not focused_node.fixed
        update()
      break
    # s
    when 83
      if focused_node
        # Toggle node inclusion in subsystem.
        if focused_node.selected
          deselectNode(focused_node)
        else
          selectNode(focused_node)
        update()
      break

  return


keyup = ->
  lastKeyDown = -1
  # Stop dragging when shift is released.
  if d3.event.keyCode is 16
    circleGroup
        .on 'mousedown.drag', null
        .on 'touchstart.drag', null
    svg.classed('shiftkey', false)


# Initialization
# =============================================================================

examples = require './examples'
# graph = examples.matlab()
# graph = examples.threshold()
# graph = examples.gatedDLatch()
graph = examples.paper()
# graph = examples.srLatch()
# graph = examples.chain 4,
#   circle: true
#   reflexive: false
#   bidirectional: true
#   k: 1

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

# Bind window resize handler.
$(window).resize resizeCanvas
# Fix nodes when they're dragged.
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


exports.graph = graph
exports.update = update
