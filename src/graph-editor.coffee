# d3 = require 'mbostock/d3'

Graph = require './graph-editor/digraph'
controls = require './graph-editor/controls'

# XXX attach past state to graph


MAXIMUM_NODES = 5
CONTAINER_SELECTOR = '#graph-editor-container'

$container = $(CONTAINER_SELECTOR)
height = 500
width = $container.width()

NODE_OFF_COLOR = d3.rgb 116, 116, 116
NODE_ON_COLOR = d3.rgb 42, 161, 152, 0.5
NODE_LABEL_COLOR = d3.rgb 255, 255, 255
NODE_RADIUS = 30


# Helpers
# =================================================================

nodeColor = (node) ->
  return (if node.on then NODE_ON_COLOR else NODE_OFF_COLOR)

# =================================================================


end_arrow_fill_color = d3.rgb()
start_arrow_fill_color = NODE_OFF_COLOR.darker

svg = d3.select(CONTAINER_SELECTOR)
  .append('svg')
    .attr('width', width)
    .attr('height', height)
    .attr('align', 'center')

######################################
# Dynamically resize SVG canvas width
######################################
resizeCanvas = ->
  # Update gloval width reference
  width = $container.width()
  # Update SVG dimensions
  svg.attr('width', width)
  # Update force layout dimensions
  force.size([width, height])
  # Redraw graph
  restart()

$(window).resize(resizeCanvas)
######################################

# define arrow markers for graph links
svg
  .append('svg:defs')
  .append('svg:marker')
    .attr('id', 'end-arrow')
    .attr('viewBox', '0 -5 10 10')
    .attr('refX', 6)
    .attr('markerWidth', 3)
    .attr('markerHeight', 3)
    .attr('orient', 'auto')
  .append('svg:path')
    .attr('d', 'M0,-5L10,0L0,5')
    .attr('fill', end_arrow_fill_color)
    .classed('arrow-head', true)

svg
  .append('svg:defs')
  .append('svg:marker')
    .attr('id', 'start-arrow')
    .attr('viewBox', '0 -5 10 10')
    .attr('refX', 4)
    .attr('markerWidth', 3)
    .attr('markerHeight', 3)
    .attr('orient', 'auto')
  .append('svg:path')
    .attr('d', 'M10,-5L0,0L10,5')
    .attr('fill', start_arrow_fill_color)
    .classed('arrow-head', true)

# line displayed when dragging new nodes
drag_line = svg
  .append('svg:path')
    .attr('class', 'link dragline hidden')
    .attr('d', 'M0,0L0,0')

# handles to link and node element groups
path = svg
  .append('svg:g')
    .selectAll('path')
circle = svg
  .append('svg:g')
    .selectAll('g')

selected_node = null
selected_link = null
mousedown_link = null
mousedown_node = null
mouseup_node = null

# mouse event vars
resetMouseVars = ->
  mousedown_node = null
  mouseup_node = null
  mousedown_link = null
  return

# update force layout (called automatically each iteration)
tick = ->
  # draw directed edges with proper padding from node centers
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
  circle.attr 'transform', (node) ->
    "translate(#{node.x},#{node.y})"
  return

# update graph (called when needed)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
restart = ->

  # Update the node and edge list
  nodes = graph.getNodes()
  links = graph.getDrawableEdges()

  # path (link) group
  path = path.data(links)

  # update existing links
  path
      .classed('selected', (edge) ->
        graph.isSameLink(edge.key, selected_link)
      ).style('marker-start', (edge) ->
        (if edge.bidirectional then 'url(#start-arrow)' else "")
      ).style('marker-end', (edge) ->
        'url(#end-arrow)'
      )

  # add new links
  path.enter()
    .append('svg:path')
      .attr('class', 'link')
      .classed('selected', (edge) ->
        edge.key is selected_link
      ).style('marker-start', (edge) ->
        (if edge.bidirectional then 'url(#start-arrow)' else '')
      ).style('marker-end', (edge) ->
        'url(#end-arrow)'
      ).on('mousedown', (edge) ->
        return if d3.event.shiftKey

        # select link
        mousedown_link = edge.key
        if mousedown_link is selected_link
          selected_link = null
        else
          selected_link = mousedown_link
        selected_node = null

        restart()
      )

  # remove old links
  path.exit().remove()

  # circle (node) group
  # NB: the function arg is crucial here! nodes are known by id, not by index!
  circle = circle.data(nodes, (d) ->
    return d._id
  )

  # update existing nodes (reflexive & selected visual states)
  circle.selectAll('circle')
      .style('fill', (node) ->
        if (node is selected_node)
          return nodeColor(node).brighter()
        else
          return nodeColor(node)
      ).attr('transform', (node) ->
        if (node is selected_node)
          return 'scale(1.1)'
      ).classed('reflexive', (node) ->
        node.reflexive
      )


  # add new nodes
  g = circle.enter().append('svg:g')

  g.append('svg:circle')
      .attr('class', 'node')
      .attr('r', NODE_RADIUS)
      .style('fill', (node) ->
        if (node is selected_node)
          nodeColor(node).brighter().toString()
        else
          nodeColor(node)
      ).classed('reflexive', (node) ->
        node.reflexive
        # TODO mouseover/mouseout
      ).on('mouseover', (node) ->
        return if not mousedown_node or node is mousedown_node
        # enlarge target node
        d3.select(this).attr('transform', 'scale(1.1)')
      ).on('mouseout', (node) ->
        return if not mousedown_node or node is mousedown_node
        # unenlarge target node
        d3.select(this).attr('transform', '')
      ).on('mousedown', (node) ->
        return if d3.event.shiftKey

        # select/deselect node
        mousedown_node = node
        if mousedown_node is selected_node then selected_node = null
        else selected_node = mousedown_node
        selected_link = null

        # reposition drag line
        drag_line
          .style('marker-end', 'url(#end-arrow)')
            .classed('hidden', false)
            .attr('d', "M#{mousedown_node.x},#{mousedown_node.y}L#{mousedown_node.x},#{mousedown_node.y}")

        restart()
      ).on('mouseup', (node) ->
        return if not mousedown_node

        # needed by FF
        drag_line
          .classed('hidden', true)
          .style('marker-end', '')

        # check for drag-to-self
        mouseup_node = node
        if mouseup_node is mousedown_node
          resetMouseVars()
          return

        # unenlarge target node
        d3.select(this).attr('transform', '')

        edge = graph.addEdge(mousedown_node._id, mouseup_node._id)

        if not edge?
          edge = graph.getEdge(mousedown_node._id, mouseup_node._id)

        # select new link
        selected_link = edge.key
        selected_node = null

        restart()
      )

  # Show node IDs.
  g.append('svg:text')
      .attr('x', 0)
      .attr('y', -6)
      .classed('node-label', true)
      .classed('id', true)
      .attr('fill', NODE_LABEL_COLOR)

  # Show node mechanisms.
  g.append('svg:text')
      .attr('x', 0)
      .attr('y', 13)
      .classed('node-label', true)
      .classed('mechanism', true)
      .attr('fill', NODE_LABEL_COLOR)

  # Update displayed mechanisms and IDs.
  circle.select('.node-label.id').text((node) -> node.label)
  circle.select('.node-label.mechanism').text((node) -> node.mechanism)

  # remove old nodes
  circle.exit().remove()

  # Rebind the nodes and links.
  force
    .nodes(nodes)
    .links(links)

  # Set the graph in motion.
  force.start()

# end of restart()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dblclick = (properties) ->
  # Prevent I-bar on drag.
  d3.event.preventDefault()
  # Because :active only works in WebKit?
  svg.classed('active', true)
  return if d3.event.shiftKey or
            mousedown_node or
            mousedown_link or
            graph.nodeSize >= MAXIMUM_NODES
  # Insert new node at this point.
  point = d3.mouse(this)
  # Add the node and start with it selected.
  selected_node = graph.addNode(
    x: point[0]
    y: point[1]
  )
  restart()


mousemove = ->
  return unless mousedown_node
  # update drag line
  drag_line.attr('d', "M#{mousedown_node.x},#{mousedown_node.y}L#{d3.mouse(this)[0]},#{d3.mouse(this)[1]}")
  restart()


mouseup = ->
  if mousedown_node
    # hide drag line
    drag_line
      .classed('hidden', true)
      .style('marker-end', '')
  # because :active only works in WebKit?
  svg.classed('active', false)
  # clear mouse event vars
  resetMouseVars()


mousedown = ->
  selected_node = null unless mousedown_node
  selected_link = null unless mousedown_link
  restart()


# only respond once per keydown
lastKeyDown = -1


keydown = ->

  switch d3.event.keyCode
    # left arrow
    when 37
      selectPreviousNode()
      restart()
      break
    # up arrow
    when 38
      selectPreviousNode()
      restart()
      break
    # right arrow
    when 39
      selectNextNode()
      restart()
      break
    # down arrow
    when 40
      selectNextNode()
      restart()
      break

  return unless lastKeyDown is -1
  lastKeyDown = d3.event.keyCode

  # shift
  if d3.event.keyCode is 16
    circle.call(force.drag)
    svg.classed('shiftkey', true)

  return if not selected_node and not selected_link

  # Node or link is selected:
  # Grab selected link source and target ids.
  if selected_link
    ids = selected_link.split(',')
    sourceId = ids[0]
    targetId = ids[1]
  switch d3.event.keyCode
    # backspace, delete
    when 8, 46
      d3.event.preventDefault()
      if selected_node
        removed = graph.removeNode(selected_node._id)
        selected_node = null
        restart()
      else if selected_link
        graph.removeEdge(sourceId, targetId)
        graph.removeEdge(targetId, sourceId)
        selected_link = null
        restart()
      break
    # d
    when 68
      if selected_link
        # Cycle through link directions:
        # Faithful selected_link -> switch
        if (graph.getEdge(sourceId, targetId) and
            not graph.getEdge(targetId, sourceId))
          graph.removeEdge(sourceId, targetId)
          graph.addEdge(targetId, sourceId)
        # Switched selected_link -> bidirectional
        else if (graph.getEdge(targetId, sourceId) and
                 not graph.getEdge(sourceId, targetId))
          graph.addEdge(sourceId, targetId)
        # Bidirectional -> faithful selected_link
        else if (graph.getEdge(sourceId, targetId) and
                 graph.getEdge(targetId, sourceId))
          graph.removeEdge(targetId, sourceId)
        restart()
      break
    # b
    when 66
      if selected_link
        graph.addEdge(sourceId, targetId)
        graph.addEdge(targetId, sourceId)
        restart()
      break
    # space
    when 32
      d3.event.preventDefault()
      if selected_node
        graph.toggleState(selected_node)
        restart()
      break
    # m
    when 77
      if selected_node
        graph.cycleMechanism(selected_node)
        restart()
      break
    # r
    when 82
      if selected_node
        graph.toggleReflexivity(selected_node)
        restart()
      break


selectNextNode = ->
  if not selected_node or selected_node.index is graph.nodeSize - 1
    selected_node = graph.getNodeByIndex(0)
  else
    selected_node = graph.getNodeByIndex(selected_node.index + 1)


selectPreviousNode = ->
  if not selected_node or selected_node.index is 0
    selected_node = graph.getNodeByIndex(graph.nodeSize - 1)
  else
    selected_node = graph.getNodeByIndex(selected_node.index - 1)


keyup = ->
  lastKeyDown = -1
  # shift
  if d3.event.keyCode is 16
    circle
        .on('mousedown.drag', null)
        .on('touchstart.drag', null)
    svg.classed('shiftkey', false)


nearestNeighbor = (node, nodes) ->
  nearest = selected_node
  minDistance = Infinity
  for n in nodes
    d = dist([node.x, node.y], [n.x, n.y])
    if d <= minDistance
      minDistance = d
      nearest = n
  return nearest


dist = (p0, p1) ->
  Math.sqrt(Math.pow(p1[0] - p0[0], 2) + Math.pow(p1[1] - p0[1], 2))


# Set up initial graph.
# =============================================================================
#
graph = new Graph()

# Bind the controls to the graph.
graph.controls = controls

graph.addNode(
  on: 1
  mechanism: 'OR'
  reflexive: false
)
graph.addNode(
  on: 0
  mechanism: 'AND'
  reflexive: false
)
graph.addNode(
  on: 0
  mechanism: 'XOR'
  reflexive: false
)

graph.addEdge(0, 2)
graph.addEdge(0, 1)
graph.addEdge(1, 0)
graph.addEdge(1, 2)
graph.addEdge(2, 0)
graph.addEdge(2, 1)

graph.setPastState([1, 1, 0])

# =============================================================================

nodes = graph.getNodes()
links = graph.getDrawableEdges()

# init D3 force layout
force = d3.layout.force()
    .nodes(nodes)
    .links(links)
    .size([width, height])
    .linkDistance(175)
    .linkStrength(0.75)
    .charge(-900)
    .on('tick', tick)

# app starts here
svg
    .on('dblclick', dblclick)
    .on('mousemove', mousemove)
    .on('mousedown', mousedown)
    .on('mouseup', mouseup)

d3.select(document)
    .on('keydown', keydown)
    .on('keyup', keyup)

restart()


exports.graph = graph


# Copyright (c) 2013-2014 Ross Kirsling

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
