###
# graph-editor/index.coffee
###

colors = require '../colors'
utils = require './utils'
Graph = require './graph'


NETWORK_SIZE_LIMIT = 10
CONTAINER_SELECTOR = '#graph-editor-container'

$container = $(CONTAINER_SELECTOR)
height = 500
width = $container.width()

NODE_RADIUS = 25
REFLEXIVE_NODE_BORDER = 4.5
SUBSYSTEM_MARKER_BORDER = 8

# New nodes will be connected to neighbors within this radius.
NEIGHBOR_RADIUS = 90
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
  .on 'mouseenter', ->
    state.onCanvas = true
    updateMouseElements()
  .on 'mouseleave', ->
    state.onCanvas = false
    updateMouseElements()

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
selectedNodes = []
state =
  onCanvas: false
  downPoint: null
  overNode: null
  overLink: null
  downNode: null
  upNode: null
  downLink: null
  selecting: false
  linking: false
  justLinked: false


# Helpers
# =====================================================================

# Update mouse-related elements based on mouse state.
updateMouseElements = ->
  # Show/hide drag line.
  drag_line
    .classed 'hidden', not state.linking
    .style 'marker-end', (if state.linking then 'url(#end-arrow)' else '')
  # Show/hide selection box.
  drag_rect.classed 'hidden', not state.selecting
  # Show/hide neighbor circle.
  neighborCircle.classed 'hidden', ->
    not state.onCanvas or
    state.overNode or
    state.dragging or
    state.linking or
    state.justLinked

nodeColor = (node) -> (if node.on then colors.node.on else colors.node.off)

focusNode = (node) ->
  focused_node = node
  focused_link = null

focusLink = (link) ->
  focused_link = link
  focused_node = null

selectNode = (node) ->
  # Add node to selected node list.
  selectedNodes.push node
  # Mark it as selected.
  node.selected = true

deselectNode = (node) ->
  # Remove node from selected node list.
  selectedNodes.splice selectedNodes.indexOf(node), 1
  # Mark it as not selected.
  node.selected = false

toggleSelect = (node) ->
  if node.selected
    deselectNode(node)
  else
    selectNode(node)

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

getNeighbors = (point) ->
  neighbors = []
  d3.selectAll 'circle.node'
    .each (node, i) ->
      dist = distance(point, [node.x, node.y])
      neighbors.push node if dist < NEIGHBOR_RADIUS + getRadius(node)
      return
  return neighbors

isDragging = (point) ->
  dragDistance = 0
  if state.downPoint
    dragDistance = distance(point, state.downPoint)
  return dragDistance > IGNORE_DRAG_THRESHOLD

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

  updateMouseElements()

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
        state.overLink = edge.key
        # Only focus link if we're not dragging a new one and not selecting
        # nodes.
        unless state.dragging
          focusLink(edge.key)
        update()
        return
      .on 'mouseout', (edge) ->
        state.overLink = false
        updateMouseElements()
        return
      .on 'mousedown', (edge) ->
        state.downLink = edge.key
        updateMouseElements()
        return
      .on 'mouseup', (edge) ->
        focusLink(edge.key)
        update()
        return
      .on 'click', (edge) ->
        ids = edge.key.split ','
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
      .on 'mouseover', (node) ->
        state.overNode = node
        # Only focus a node if it's a new one and we haven't just finished
        # dragging a new link.
        unless state.linking or state.justLinked or node is state.upNode
          focusNode(node)
          # Enlarge target node.
          d3.select(this).attr 'transform', 'scale(1.1)'
        update()
        return
      .on 'mouseleave', (node) ->
        state.justLinked = false
        state.upNode = null
        unless state.downNode
          state.linking = false
        updateMouseElements()
        return
      .on 'mouseout', (node) ->
        state.overNode = null
      .on 'mousedown', (node) ->
        state.downNode = node
        focusNode(node)
        unless d3.event.shiftKey
          # Reset drag line.
          drag_line
            .attr
              d: "M#{node.x},#{node.y}L#{node.x},#{node.y}"
        update()
        return
      .on 'mouseup', (node) ->
        if state.linking and not (node is state.downNode)
          state.justLinked = true
          edge = graph.addEdge state.downNode._id, node._id
          if not edge?
            edge = graph.getEdge state.downNode._id, node._id
          focusLink(edge.key)
        state.upNode = node
        update()
        return
      .on 'click', (node) ->
        if d3.event.shiftKey or d3.event.metaKey
          toggleSelect(node)
        else unless state.linking
          graph.toggleState node
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


dblclick = ->
  point = d3.mouse(this)
  # Don't create a new node if we're holding shift/meta, dragging, mousing-over
  # a node or link, or the network size limit has been reached.
  unless d3.event.shiftKey or
         d3.event.metaKey or
         state.overNode or
         state.overLink or
         state.dragging or
         graph.nodeSize >= NETWORK_SIZE_LIMIT
    d3.event.preventDefault()
    # Insert new node, connecting it to nearby nodes.
    newNode =
      x: point[0]
      y: point[1]
      neighbors: getNeighbors(point)
    newNode = graph.addNode(newNode)
    # Start with the node focused.
    focusNode(newNode)
    update()
  return


click = ->
  point = d3.mouse(this)
  if d3.event.metaKey and not state.dragging and not state.overNode
    neighbors = getNeighbors(point)
    for i in neighbors
      for j in neighbors
        graph.addEdge(i._id, j._id) unless i is j
  update()
  return


mousemove = ->
  point = d3.mouse(this)
  if isDragging(point)
    state.dragging = true

  # Update neighbor circle.
  neighborCircle.attr
    cx: point[0]
    cy: point[1]

  # Update drag line.
  n = state.downNode
  if n
    drag_line.attr 'd', "M#{n.x},#{n.y}L#{point[0]},#{point[1]}"

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

  if state.selecting and state.dragging
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
            focusNode(selectedNodes[selectedNodes.length - 1])
          if node.selected
            deselectNode(node)
        return

  update()
  return


mouseup = ->
  state.linking = false
  state.selecting = false
  state.dragging = false
  state.downNode = null
  state.downPoint = null
  # Because :active only works in WebKit?
  svg.classed 'active', false
  update()

mousedown = ->
  state.downPoint = d3.mouse(this)

  if state.downNode and not d3.event.shiftKey
    state.linking = true
  else
    state.selecting = true
    # Unfocus nodes and edges.
    focused_link = null
    focused_node = null
    # Redraw selection box starting at mouse.
    drag_rect.attr
      x: state.downPoint[0]
      y: state.downPoint[1]
      width: 0
      height: 0
    # Clear selection unless holding Shift or Command/Alt.
    unless d3.event.shiftKey or
           d3.event.metaKey
      selectedNodes = []
      d3.selectAll 'circle.node'
        .each deselectNode

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
      if selectedNodes.length > 0
        graph.removeNodes selectedNodes
        selectedNodes = []
        focusPreviousNode()
        update()
      else if focused_node
        removed = graph.removeNode focused_node
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
      if selectedNodes.length > 0
        graph.toggleStates selectedNodes
        for node in selectedNodes
          logChange(node, 'state', 'on')
        update()
      else if focused_node
        graph.toggleState focused_node
        logChange(focused_node, 'state', 'on')
        update()
      break
    # m
    when 77
      if selectedNodes.length > 0
        graph.cycleMechanisms selectedNodes
        for node in selectedNodes
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
      if selectedNodes.length > 0
        graph.toggleSelfLoops selectedNodes
        for node in selectedNodes
          logChange(node, 'reflexivity', 'reflexive')
        update()
      else if focused_node
        graph.toggleSelfLoop focused_node
        logChange(focused_node, 'reflexivity', 'reflexive')
        update()
      break
    # f
    when 70
      if selectedNodes.length > 0
        initial = selectedNodes[0].fixed
        for node in selectedNodes
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
    .on 'click', click
    .on 'mousemove', mousemove
    .on 'mousedown', mousedown
    .on 'mouseup', mouseup
# Bind global keyboard handlers.
d3.select document
    .on 'keydown', keydown
    .on 'keyup', keyup

# Go go go!
update()


class GraphEditor
  constructor: (@graph) ->

  update: update

  load: (jsonGraph) ->
    graph = new Graph()
    @graph = graph
    @graph.loadJSON(jsonGraph)
    update()
    return

module.exports = new GraphEditor(graph)
