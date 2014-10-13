d3 = require 'mbostock/d3'


Graph = require './digraph'
tpmify = require './tpmify'
mechanism = require './mechanism'

graph = new Graph()

graph.addNode('0', 1)
  .mechanism = mechanism["OR"]
graph.addNode('1', 0)
  .mechanism = mechanism["COPY"]
graph.addNode('2', 0)
  .mechanism = mechanism["XOR"]

graph.addEdge(0, 2)
graph.addEdge(1, 0)
graph.addEdge(1, 2)
graph.addEdge(2, 0)
graph.addEdge(2, 1)


# set up SVG for D3
width = 688
height = 500

node_off_color = d3.rgb 136, 136, 136
node_on_color = d3.rgb 42, 161, 152
node_label_color = d3.rgb 238, 238, 238
node_radius = 18

node_color = (node) ->
  return (if node.on then node_on_color else node_off_color)

end_arrow_fill_color = d3.rgb()
start_arrow_fill_color = node_off_color.darker

svg = d3.select('#vphi')
  .append('svg')
    .attr('width', width)
    .attr('height', height)
    .attr('align', 'center')

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
  path.attr "d", (d) ->
    deltaX = d.target.x - d.source.x
    deltaY = d.target.y - d.source.y
    dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
    normX = deltaX / dist
    normY = deltaY / dist
    sourcePadding = (if d.left then node_radius + 5 else node_radius)
    targetPadding = (if d.right then node_radius + 5 else node_radius)
    sourceX = d.source.x + (sourcePadding * normX)
    sourceY = d.source.y + (sourcePadding * normY)
    targetX = d.target.x - (targetPadding * normX)
    targetY = d.target.y - (targetPadding * normY)
    return "M#{sourceX},#{sourceY}L#{targetX},#{targetY}"

  circle.attr 'transform', (d) ->
    "translate(#{d.x},#{d.y})"

  return

# update graph (called when needed)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
restart = ->

  # path (link) group
  path = path.data(links)

  # update existing links
  path
      .classed('selected', (d) ->
        d is selected_link
      ).style('marker-start', (d) ->
        (if d.left then 'url(#start-arrow)' else "")
      ).style('marker-end', (d) ->
        (if d.right then 'url(#end-arrow)' else "")
      )

  # add new links
  path.enter()
    .append('svg:path')
      .attr('class', 'link')
      .classed("selected", (d) ->
        d is selected_link
      ).style('marker-start', (d) ->
        (if d.left then 'url(#start-arrow)' else '')
      ).style('marker-end', (d) ->
        (if d.right then 'url(#end-arrow)' else '')
      ).on('mousedown', (d) ->
        return if d3.event.shiftKey

        # select link
        mousedown_link = d
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
    return d.id
  )

  # add new nodes
  g = circle.enter().append('svg:g')

  # update existing nodes (reflexive & selected visual states)
  circle.selectAll('circle')
      .style('fill', (d) ->
        if (d is selected_node)
          return node_color(d).brighter()
        else
          return node_color(d)
      ).attr('transform', (d) ->
        if (d is selected_node)
          return 'scale(1.1)'
      ).classed('reflexive', (d) ->
        d.reflexive
      )

  g.append('svg:circle')
      .attr('class', 'node')
      .attr('r', node_radius)
      .style('fill', (d) ->
        if (d is selected_node)
          node_color(d).brighter().toString()
        else
          node_color(d)
      ).classed('reflexive', (d) ->
        d.reflexive
        # TODO mouseover/mouseout
      ).on('mouseover', (d) ->
        return if not mousedown_node or d is mousedown_node
        # enlarge target node
        d3.select(this).attr('transform', 'scale(1.1)')
      ).on('mouseout', (d) ->
        return if not mousedown_node or d is mousedown_node
        # unenlarge target node
        d3.select(this).attr("transform", "")
      ).on('mousedown', (d) ->
        return if d3.event.shiftKey

        # select node
        mousedown_node = d
        if mousedown_node is selected_node then selected_node = null
        else selected_node = mousedown_node
        selected_link = null

        # reposition drag line
        drag_line
          .style('marker-end', 'url(#end-arrow)')
            .classed('hidden', false)
            .attr('d', "M#{mousedown_node.x},#{mousedown_node.y}L#{mousedown_node.x},#{mousedown_node.y}")

        restart()
      ).on('mouseup', (d) ->
        return if not mousedown_node

        # needed by FF
        drag_line
          .classed('hidden', true)
          .style('marker-end', '')

        # check for drag-to-self
        mouseup_node = d
        if mouseup_node is mousedown_node
          resetMouseVars()
          return

        # unenlarge target node
        d3.select(this).attr('transform', '')

        # add link to graph (update if exists)
        # NB: links are strictly source < target; arrows separately specified by
        # booleans
        if mousedown_node.id < mouseup_node.id
          source = mousedown_node
          target = mouseup_node
          direction = 'right'
        else
          source = mouseup_node
          target = mousedown_node
          direction = 'left'

        link = links.filter(
          (l) ->
            return (l.source is source and l.target is target)
        )[0]

        if link
          link[direction] = true
        else
          link =
            source: source
            target: target
            left: false
            right: false

          link[direction] = true
          links.push link

        # select new link
        selected_link = link
        selected_node = null
        restart()
      )

  # show node IDs
  g.append('svg:text')
      .attr('x', 0)
      .attr('y', 4)
      .attr('class', 'id')
      .attr('fill', node_label_color)
      .text((d) ->
        d.id
      )

  # remove old nodes
  circle.exit().remove()

  d3.selectAll('.id')
    .data(nodes)
    .text((d) -> d.id)

  # set the graph in motion
  force.start()

# end of restart()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


dblclick = ->

  # prevent I-bar on drag
  #d3.event.preventDefault();

  # because :active only works in WebKit?
  svg.classed('active', true)
  return if d3.event.shiftKey or mousedown_node or mousedown_link

  # insert new node at point
  point = d3.mouse(this)
  node =
    id: ++lastNodeId
    reflexive: false

  node.x = point[0]
  node.y = point[1]
  nodes.push(node)

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
  restart()


spliceLinksForNode = (node) ->
  toSplice = links.filter (l) ->
    l.source is node or l.target is node
  toSplice.map (l) ->
    links.splice(links.indexOf(l), 1)

# only respond once per keydown
lastKeyDown = -1

keydown = ->
  return unless lastKeyDown is -1
  d3.event.preventDefault()
  lastKeyDown = d3.event.keyCode

  # shift
  if d3.event.keyCode is 16
    circle.call(force.drag)
    svg.classed('shiftkey', true)

  return if not selected_node and not selected_link
  switch d3.event.keyCode
    # backspace, delete
    when 8, 46
      if selected_node
        nodes.splice(nodes.indexOf(selected_node), 1)
        spliceLinksForNode(selected_node)
      else if selected_link
        links.splice(links.indexOf(selected_link), 1)
      selected_link = null
      selected_node = null
      restart()
      break
    # D
    when 68
      if selected_link
        # cycle through link directions:
        # both -> right
        if selected_link.left is true and selected_link.right is true
          selected_link.left = false
        # right -> left
        else if selected_link.left is false and selected_link.right is true
          selected_link.left = true
          selected_link.right = false
        # left -> both
        else if selected_link.left is true and selected_link.right is false
          selected_link.right = true
      restart()
      break
    # B
    when 66
      if selected_link
        # set link direction to both left and right
        selected_link.left = true
        selected_link.right = true
      restart()
      break
    # L
    when 76
      if selected_link
        # set link direction to left only
        selected_link.left = true
        selected_link.right = false
      restart()
      break
    # R
    when 82
      if selected_node
        # toggle node reflexivity
        selected_node.reflexive = not selected_node.reflexive
      else if selected_link
        # set link direction to right only
        selected_link.left = false
        selected_link.right = true
      restart()
      break
    # space
    when 32
      if selected_node
        # toggle node on/off
        selected_node.on = not selected_node.on
      restart()
      break

keyup = ->
  lastKeyDown = -1

  # shift
  if d3.event.keyCode is 16
    circle
        .on('mousedown.drag', null)
        .on('touchstart.drag', null)
    svg.classed('shiftkey', false)

# set up initial nodes and links
#  - nodes are known by 'id', not by index in array.
#  - reflexive edges are indicated on the node (as a bold black circle).
#  - links are always source < target; edge directions are set by 'left' and
#    'right'.
nodes = [
  {id: 0, on: true, reflexive: false, mechanism: 'AND'}
  {id: 1, on: false, reflexive: true, mechanism: 'AND'}
  {id: 2, on: true, reflexive: false, mechanism: 'COPY'}
  {id: 3, on: false, reflexive: false, mechanism: 'OR'}
]
lastNodeId = 3
links = [
  {source: nodes[0], target: nodes[1], left: false, right: true}
  {source: nodes[0], target: nodes[2], left: true, right: false}
  {source: nodes[0], target: nodes[3], left: false, right: true}
  {source: nodes[1], target: nodes[2], left: false, right: true}
  {source: nodes[1], target: nodes[3], left: true, right: false}
  {source: nodes[2], target: nodes[3], left: true, right: true}
]

# init D3 force layout
force = d3.layout.force()
    .nodes(nodes)
    .links(links)
    .size([width, height])
    .linkDistance(150)
    .charge(-700)
    .on('tick', tick)

# app starts here
svg
    .on('dblclick', dblclick)
    .on('mousemove', mousemove)
    .on('mousedown', mousedown)
    .on('mouseup', mouseup)

d3.select(window)
    .on('keydown', keydown)
    .on('keyup', keyup)

restart()


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
