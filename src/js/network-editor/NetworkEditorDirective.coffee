'use strict'
###
# concept-space/NetworkEditorDirective.coffee
###

colors = require '../colors'
networkService = require '../services/network'


NODE_RADIUS = 25
REFLEXIVE_NODE_BORDER = 4.5
SUBSYSTEM_MARKER_BORDER = 8

# New nodes will be connected to neighbors within this radius.
NEIGHBOR_RADIUS = 90
# The radius within which to ignore dragging.
IGNORE_DRAG_THRESHOLD = 10

# TODO use indices instead of ids throughout (refactor network service as well)

module.exports = [
  networkService.name
  'CANVAS_HEIGHT'
  'NETWORK_SIZE_LIMIT'
  (network, CANVAS_HEIGHT, NETWORK_SIZE_LIMIT) ->
    link: (scope, element, attrs) ->

      # State
      # =====================================================================

      focusedNode = null
      focusedEdgeKey = null
      selectedNodes = []
      # Only respond once per keydown.
      lastKeyDown = -1
      mouseState =
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


      # Globals
      # =====================================================================

      width = element.width()

      # Declare the canvas.
      svg = d3.select element[0]
        .append 'svg'
          .attr
            width: width
            height: CANVAS_HEIGHT
            align: 'center'
      # Paint the background black.
      background = svg.append 'rect'
        .attr
          width: width
          height: CANVAS_HEIGHT
          fill: colors.black

      # Draggable node selection box
      dragRect = svg
        .append 'svg:rect'
          .attr
            class: 'selection-box hidden'
            x: 0
            y: 0
            width: 0
            height: 0

      # Line displayed when dragging new nodes.
      dragLine = svg
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
          mouseState.onCanvas = true
          updateMouseElements()
        .on 'mouseleave', ->
          mouseState.onCanvas = false
          updateMouseElements()

      # Handles to link and node element groups.
      path = svg
        .append 'svg:g'
          .selectAll 'path'
      circleGroup = svg
        .append 'svg:g'
          .selectAll 'g'

      # Define arrow markers for network edges.
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


      # Helpers
      # =====================================================================

      # Update mouse-related elements based on mouse mouseState.
      updateMouseElements = ->
        # Show/hide drag line.
        dragLine
          .classed 'hidden', not mouseState.linking
          .style 'marker-end', (
            if mouseState.linking then 'url(#end-arrow)' else ''
          )
        # Show/hide selection box.
        dragRect.classed 'hidden', not mouseState.selecting
        # Show/hide neighbor circle.
        neighborCircle.classed 'hidden', ->
          not mouseState.onCanvas or
          mouseState.overNode or
          mouseState.dragging or
          mouseState.linking or
          mouseState.justLinked or
          d3.event?.shiftKey

      nodeColor = (node) -> (
        if node.on then colors.node.on else colors.node.off
      )

      focusNode = (node) ->
        # Only focus node if there are no selected nodes.
        unless selectedNodes.length > 0
          focusedNode = node
          focusedEdgeKey = null

      focusEdge = (edge) ->
        focusedEdgeKey = edge.key
        focusedNode = null

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
          unless selectedNodes.length > 0
            focusNode(node)
        else
          selectNode(node)
          focusedNode = null

      getRadius = (node) ->
        r = NODE_RADIUS
        if node.reflexive
          r += REFLEXIVE_NODE_BORDER
        if node is focusedNode
          r += NODE_RADIUS * 0.1
        return r

      focusNextNode = ->
        if not focusedNode or focusedNode.index is network.size() - 1
          focusNode(network.getNode 0)
        else
          focusNode(network.getNode(focusedNode.index + 1))

      focusPreviousNode = ->
        if not focusedNode or focusedNode.index is 0
          focusNode(network.getNode(network.size() - 1))
        else
          focusNode(network.getNode(focusedNode.index - 1))

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
        if mouseState.downPoint
          dragDistance = distance(point, mouseState.downPoint)
        return dragDistance > IGNORE_DRAG_THRESHOLD

      deltaDistance = (dx, dy) ->
        Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))

      distance = (p1, p2) ->
        dx = p2[0] - p1[0]
        dy = p2[1] - p1[1]
        deltaDistance(dx, dy)

      nearestNeighbor = (node, nodes) ->
        nearest = focusedNode
        minDistance = Infinity
        for n in nodes
          d = distance [node.x, node.y], [n.x, n.y]
          if d <= minDistance
            minDistance = d
            nearest = n
        return nearest

      logChange = (node, propertyName, property) ->
        log.debug "network_EDITOR: Set node #{node.label} #{propertyName} to " +
                  "#{node[property]}."


      # Update
      # =====================================================================

      update = ->

        updateMouseElements()

        # Update the node and edge list.
        nodes = network.getNodes()
        edges = network.getDrawableEdges()

        # Bind newly-fetched edges to path selection.
        path = path.data(edges)
        # Add new edges.
        path.enter()
          .append 'svg:path'
            .attr 'class', 'link'
            .attr 'stroke', colors.link.line
            .classed 'focused', (edge) ->
              network.isSameLink(edge.key, focusedEdgeKey)
            .style 'marker-start', (edge) ->
              (if edge.bidirectional then 'url(#start-arrow)' else '')
            .style 'marker-end', (edge) ->
              'url(#end-arrow)'
            .on 'mouseenter', (edge) ->
              mouseState.overLink = edge
              # Only focus link if we're not dragging a new one and not
              # selecting nodes.
              unless mouseState.dragging
                focusEdge(edge)
              update()
              return
            .on 'mouseleave', (edge) ->
              mouseState.overLink = false
              updateMouseElements()
              return
            .on 'mousedown', (edge) ->
              mouseState.downLink = edge
              updateMouseElements()
              return
            .on 'mouseup', (edge) ->
              update()
              return
            .on 'click', (edge) ->
              ids = focusedEdgeKey.split(',')
              source = network.getNodeById ids[0]
              target = network.getNodeById ids[1]
              network.cycleDirection(source, target)
              update()
              return
        # Update existing edges.
        path
            .classed 'focused', (edge) ->
              network.isSameLink(edge.key, focusedEdgeKey)
            .style 'marker-start', (edge) ->
              (if edge.bidirectional then 'url(#start-arrow)' else "")
            .style 'marker-end', (edge) ->
              'url(#end-arrow)'
        # Remove old edges.
        path.exit().remove()

        # Bind newly-fetched nodes to circle selection.
        # NB: Nodes are known by the network's internal ID, not by d3 index!
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
              mouseState.overNode = node
              # Only focus a node if it's a new one, we haven't just finished
              # dragging a new link, and we're not dragging the selection box.
              unless mouseState.linking or
                     mouseState.justLinked or
                     mouseState.selecting or
                     node is mouseState.upNode
                focusNode(node)
              update()
              return
            .on 'mouseleave', (node) ->
              mouseState.justLinked = false
              mouseState.upNode = null
              unless mouseState.downNode
                mouseState.linking = false
              updateMouseElements()
              return
            .on 'mouseout', (node) ->
              mouseState.overNode = null
            .on 'mousedown', (node) ->
              mouseState.downNode = node
              focusNode(node)
              unless d3.event.shiftKey
                # Reset drag line.
                dragLine
                  .attr
                    d: "M#{node.x},#{node.y}L#{node.x},#{node.y}"
              update()
              return
            .on 'mouseup', (node) ->
              if mouseState.dragging
                mouseState.justDragged = true
              if mouseState.linking and not (node is mouseState.downNode)
                mouseState.justLinked = true
                edge = network.addEdge mouseState.downNode, node
                if not edge?
                  edge = network.getEdge mouseState.downNode, node
                focusEdge(edge)
              mouseState.upNode = node
              update()
              return
            .on 'click', (node) ->
              if ((d3.event.shiftKey or d3.event.metaKey) and
                  not mouseState.justDragged)
                toggleSelect(node)
              else unless mouseState.linking or mouseState.justDragged
                network.toggleState node
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
        # Note: since we appended to the enter selection, this will be applied
        # to the new circle elements we just created.
        circleGroup.selectAll 'circle.node'
            .style 'fill', (node) ->
              # Brighten the focused node.
              if (node is focusedNode)
                return nodeColor(node).brighter(0.5)
              else
                return nodeColor(node)
            .classed 'on', (node) -> node.on
            .classed 'off', (node) -> not node.on
            .classed 'reflexive', (node) -> node.reflexive
            .attr 'r', (node) ->
              # Strokes are centered on the edge of the shape, so we need to
              # extend the radius by half the desired border width to keep the
              # percieved radius the same.
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
              if (node is focusedNode)
                return 'scale(1.1)'
        # Update displayed mechanisms and IDs.
        circleGroup.selectAll 'text'
          .style 'fill', (node) ->
            if node.on
              return colors.node.label.on
            else
              return colors.node.label.off
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

        # Rebind the nodes and edges to the force layout.
        force
          .nodes nodes
          .links edges

        # Set the network in motion.
        force.start()
        return


      # Mouse handlers
      # =====================================================================

      svg
          .on 'dblclick', ->
            point = d3.mouse(svg[0][0])
            # Don't create a new node if we're holding shift/meta, dragging,
            # mousing-over a node or link, or the network size limit has been
            # reached.
            console.log mouseState
            unless d3.event.shiftKey or
                   d3.event.metaKey or
                   mouseState.overNode or
                   mouseState.overLink or
                   mouseState.dragging or
                   network.size() >= NETWORK_SIZE_LIMIT
              d3.event.preventDefault()
              # Insert new node, connecting it to nearby nodes.
              newNode =
                x: point[0]
                y: point[1]
                neighbors: getNeighbors(point)
              newNode = network.addNode(newNode)
              # Start with the node focused.
              focusNode(newNode)
              update()
            return
          .on 'click', ->
            point = d3.mouse(svg[0][0])
            if (d3.event.metaKey and
                not mouseState.dragging and
                not mouseState.overNode)
              neighbors = getNeighbors(point)
              edges = []
              for i in neighbors
                for j in neighbors
                  edges.push [i, j] unless i is j
              network.addEdges(edges)
            update()
            return
          .on 'mousemove', ->
            point = d3.mouse(svg[0][0])
            if isDragging(point)
              mouseState.dragging = true

            # Update neighbor circle.
            neighborCircle.attr
              cx: point[0]
              cy: point[1]

            # Update drag line.
            n = mouseState.downNode
            if n
              dragLine.attr 'd', "M#{n.x},#{n.y}L#{point[0]},#{point[1]}"

            # Update selection box.
            d =
              x: parseInt(dragRect.attr('x'), 10)
              y: parseInt(dragRect.attr('y'), 10)
              width: parseInt(dragRect.attr('width'), 10)
              height: parseInt(dragRect.attr('height'), 10)

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

            dragRect.attr d

            if mouseState.selecting and mouseState.dragging
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
                      selectNode(node)
                  else if node.selected and not d3.event.shiftKey
                    deselectNode(node)
                  return

            update()
            return
          .on 'mousedown', ->
            mouseState.justDragged = false
            mouseState.downPoint = d3.mouse(svg[0][0])
            return if d3.event.shiftKey and mouseState.overNode

            if mouseState.downNode
              mouseState.linking = true
            else unless mouseState.overLink
              mouseState.selecting = true
              # Unfocus nodes and edges.
              focusedNode = null
              unless mouseState.overLink
                focusedEdgeKey = null
              # Redraw selection box starting at mouse.
              dragRect.attr
                x: mouseState.downPoint[0]
                y: mouseState.downPoint[1]
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
          .on 'mouseup', ->
            mouseState.linking = false
            mouseState.selecting = false
            mouseState.dragging = false
            mouseState.downNode = null
            mouseState.downPoint = null
            # Because :active only works in WebKit?
            svg.classed 'active', false
            update()


      # Keyboard handlers
      # =====================================================================

      d3.select document
          .on 'keydown', ->
            switch d3.event.keyCode
              # Left arrow.
              when 37
                focusPreviousNode()
                update()
                break
              # Right arrow.
              when 39
                focusNextNode()
                update()
                break

            return unless lastKeyDown is -1
            lastKeyDown = d3.event.keyCode

            # shift
            if d3.event.keyCode is 16
              circleGroup.call force.drag
              updateMouseElements()

            return unless focusedNode or
                          focusedEdgeKey or
                          selectedNodes.length > 0

            # Node or link is focused:
            # Grab focused link source and target ids.
            if focusedEdgeKey
              ids = focusedEdgeKey.split(',')
              source = network.getNodeById ids[0]
              target = network.getNodeById ids[1]
            switch d3.event.keyCode
              # backspace, delete, d
              when 8, 46, 68
                if selectedNodes.length > 0
                  network.removeNodes selectedNodes
                  selectedNodes = []
                  focusPreviousNode()
                  update()
                else if focusedNode
                  removed = network.removeNode focusedNode
                  focusPreviousNode()
                  update()
                else if focusedEdgeKey
                  network.removeEdge source, target
                  network.removeEdge target, source
                  focusedEdgeKey = null
                  update()
                break
              # c
              when 67
                if focusedEdgeKey
                  network.cycleDirection(source, target)
                  update()
                break
              # b
              when 66
                if focusedEdgeKey
                  network.addEdge source, target
                  network.addEdge target, source
                  update()
                break
              # space
              when 32
                console.log selectedNodes
                if selectedNodes.length > 0
                  network.toggleStates selectedNodes
                  for node in selectedNodes
                    logChange(node, 'state', 'on')
                  update()
                else if focusedNode
                  network.toggleState focusedNode
                  logChange(focusedNode, 'state', 'on')
                  update()
                break
              # m
              when 77
                if selectedNodes.length > 0
                  network.cycleMechanisms selectedNodes
                  for node in selectedNodes
                    logChange(node, 'state', 'on')
                  update()
                else if focusedNode
                  network.cycleMechanism focusedNode
                  logChange(focusedNode, 'mechanism', 'mechanism')
                  update()
                break
              # t
              when 84
                if selectedNodes.length > 0
                  network.cycleThresholds selectedNodes
                  for node in selectedNodes
                    logChange(node, 'threshold', 'threshold')
                  update()
                else if focusedNode
                  network.cycleThreshold focusedNode
                  logChange(focusedNode, 'threshold', 'threshold')
                  update()
                break
              # r
              when 82
                if selectedNodes.length > 0
                  network.toggleSelfLoops selectedNodes
                  for node in selectedNodes
                    logChange(node, 'reflexivity', 'reflexive')
                  update()
                else if focusedNode
                  network.toggleSelfLoop focusedNode
                  logChange(focusedNode, 'reflexivity', 'reflexive')
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
                else if focusedNode
                  # Free/fix node
                  focusedNode.fixed = not focusedNode.fixed
                  update()
                break
              # s
              when 83
                if focusedNode
                  # Toggle node inclusion in subsystem.
                  if focusedNode.selected
                    deselectNode(focusedNode)
                  else
                    selectNode(focusedNode)
                  update()
                break

            return
          .on 'keyup', ->
            lastKeyDown = -1
            updateMouseElements()
            # Stop dragging when shift is released.
            if d3.event.keyCode is 16
              circleGroup
                  .on 'mousedown.drag', null
                  .on 'touchstart.drag', null
              svg.classed('shiftkey', false)


      # Initialization
      # =====================================================================

      # Initialize D3 force layout.
      force = d3.layout.force()
          .size [width, CANVAS_HEIGHT]
          .linkDistance 175
          .linkStrength 0.75
          .charge -900
          .on 'tick', ->
            # Draw directed edges with proper padding from node centers.
            path.attr 'd', (edge) ->
              dx = edge.target.x - edge.source.x
              dy = edge.target.y - edge.source.y
              dist = deltaDistance dx, dy
              normX = dx / dist
              normY = dy / dist

              # Draw the line to the edge of the circle, not the center.
              sourcePadding = getRadius(edge.source)
              targetPadding = getRadius(edge.target)

              # Paddding for arrowheads.
              targetPadding += 7
              if edge.bidirectional
                sourcePadding += 7

              sourceX = edge.source.x + (sourcePadding * normX)
              sourceY = edge.source.y + (sourcePadding * normY)
              targetX = edge.target.x - (targetPadding * normX)
              targetY = edge.target.y - (targetPadding * normY)
              return "M#{sourceX},#{sourceY}L#{targetX},#{targetY}"
            circleGroup.attr 'transform', (node) ->
              "translate(#{node.x},#{node.y})"
            return

      # Bind window resize handler.
      $(window).resize ->
        # Update gloval width reference
        width = element.width()
        # Update SVG dimensions
        svg.attr 'width', width
        background.attr 'width', width
        # Update force layout dimensions
        force.size [width, CANVAS_HEIGHT]
        # Redraw network
        update()
        return

      # Fix nodes when they're dragged.
      force.drag()
        .on 'dragstart', (node) -> node.fixed = true

      # Go go go!
      update()

      # TODO! now that this is here, reduce calls to update if possible
      # Update when network is updated.
      scope.$on (networkService.name + '.updated'), update

]
