# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# edge-ui.coffee
#

# Edge class
#   Models directed edge between two nodes (no self-loop)
class Edge
    @name: "Edge"

    canvas: null
    
    srcNode: null
    dstNode: null
    
    value: null  # currently unused
    
    # visual components of an edge
    line: null
    arrow: null
    
    constructor: (@srcNode, @canvas) ->

        @line = new fabric.Line([srcNode.getLeft(), srcNode.getTop(),
                                srcNode.getLeft(), srcNode.getTop()],
            stroke: 'black'
            strokeWidth: 3
            padding: 10
        )
        @line.selectable = false

        @arrow = new fabric.Triangle(
                width: 15
                height: 20
                visible: false
            )
        @arrow.selectable = false
        
        @line._edge = @arrow._edge = this
        
    setDestNode: (@dstNode) ->
        @arrow.set(visible: true)

        # update the arrow position/orientation
        @update()
        
    setDestPos: (dstPos) ->
        @line.set(
            x2: dstPos.x
            y2: dstPos.y
        )
    
    sendBackwards: ->
        @line.sendBackwards()
        
    sendToBack: ->
        @line.sendToBack()
        
    bringForwards: ->
        @line.bringForwards()
        
    bringToFront: ->
        @line.bringToFront()

    # call when nodes or nodes' underlying position params have changed
    update: ->
        # update line/arrow params
        [x1, y1, x2, y2] = [@srcNode.getLeft(),
                            @srcNode.getTop(),
                            @dstNode.getLeft(),
                            @dstNode.getTop()]
        
        angle = util.getAngle(y2-y1, x2-x1)
        
        x1 += Math.cos(angle) * @srcNode.radius()
        y1 += Math.sin(angle) * @srcNode.radius()
        
        x2 -= Math.cos(angle) * (@dstNode.radius() + @arrow.getHeight()/2)
        y2 -= Math.sin(angle) * (@dstNode.radius() + @arrow.getHeight()/2)
        
        length = Math.sqrt(Math.pow(x2-x1, 2) + Math.pow(y2-y1, 2))
        
        # rather than provide endpoints for line directly, we draw a
        # horizontal line through the midpoint, and then rotate it,
        # so that we get a tight bounding box for events (like hover)
        @line.set(
            x1: (x1+x2)/2 - length/2
            y1: (y1+y2)/2
            x2: (x1+x2)/2 + length/2
            y2: (y1+y2)/2
            angle: util.toDeg(angle)
        ).setCoords()
        
        @arrow.set(
            left: x2
            top: y2
            angle: util.toDeg(angle)+90
        ).setCoords()

    activateHover: () ->
        console.log('activateHover()')
        @line.setStroke('red')
        @arrow.setFill('red')

    deactivateHover: () ->
        @line.setStroke('black')
        @arrow.setFill('black')

    display: () ->
        @canvas.add(@line)
        @canvas.add(@arrow)
        
    hide: () ->
        @canvas.remove(@line)
        @canvas.remove(@arrow)
        
    remove: ({node} = {}) ->
        @hide()
        @srcNode.removeEdge(this) unless node == @srcNode
        @dstNode.removeEdge(this) unless node == @dstNode
        
    equals: (otherEdge) ->
        return (@srcNode == otherEdge.srcNode and
                @dstNode == otherEdge.dstNode)



# SelfEdge
#   Models self-loop
class SelfEdge
    @name: "SelfEdge"

    canvas: null
    
    node: null
    
    # for type compatability with Edge
    srcNode: null
    dstNode: null
    
    value: null  # currently unused
    
    # visual component for self-loop
    arc: null
    
    constructor: (@node, @canvas) ->
        @srcNode = @dstNode = @node
        
        @arrow = new fabric.Triangle(
                width: 15
                height: 15
                angle: 125 + 90
                visible: false
        )
        @arrow.selectable = false

        @arc = @_createArc()
        
        @arc._edge = @arrow._edge = this

        @update()
        
        @arc.set(visible: true)
        @arrow.set(visible: true)
        
    sendBackwards: ->
        @arc.sendBackwards()
        @arrow.sendBackwards()
        
    sendToBack: ->
        @arrow.sendToBack()
        @arc.sendToBack()
        
    bringForwards: ->
        @arc.bringForwards()
        @arrow.bringForwards()
        
    bringToFront: ->
        @arc.bringToFront()
        @arrow.bringToFront()

    _computeEdgeEndpoints: (node) ->
        # offset to arc start/end points (pi/4 on lt, rt circle sections)
        nodeX = node.getLeft()
        nodeY = node.getTop()
        
        offset = Math.cos(util.toRad(45)) * node.radius()

        x1 = nodeX - offset
        y1 = nodeY - offset

        x2 = nodeX + offset
        y2 = y1
        
        return {
            x1: x1
            y1: y1
            x2: x2
            y2: y2
        }
    
    # fabric arrow at angle 0 deg really maps to -90 deg in our coordinate system
    _trueArrowAngleRad: (arrow) ->
        return util.toRad(arrow.getAngle() - 90)
        
    _createArc: ->
        # handle self-loop arc
        endpoints = @_computeEdgeEndpoints(@node)

        arcRadius = 1.1 * @node.radius()
        arrowAngle = @_trueArrowAngleRad(@arrow)
        
        # start of arc
        arcX1 = endpoints.x1
        arcY1 = endpoints.y1
        
        # end arc at midpoint of arrow base
        arcX2 = endpoints.x2 - Math.cos(arrowAngle) * @arrow.getHeight()
        arcY2 = endpoints.y2 - Math.sin(arrowAngle) * @arrow.getHeight()
        
        pathString = "M #{arcX1} #{arcY1} " +
                     "A #{arcRadius} #{arcRadius} 0 1 1 #{arcX2} #{arcY2}"

        arc = new fabric.Path(pathString)
        arc.set(
            fill: 'none'
            stroke: 'black'
            strokeWidth: 3)
        arc.selectable = false

        return arc

    # call when nodes or nodes' underlying position params have changed
    update: ->
        
        edgeEndpoints = @_computeEdgeEndpoints(@node)

        # left/top is based on midpoint of arc
        @arc.set(
            left: edgeEndpoints.x1 + @arc.getWidth() / 2
            top: edgeEndpoints.y1 - @arc.getHeight() / 2
        ).setCoords()
        
        angle = @_trueArrowAngleRad(@arrow)
        arrowX = edgeEndpoints.x2 - Math.cos(angle)*(@arrow.getHeight()/2)
        arrowY = edgeEndpoints.y2 - Math.sin(angle)*(@arrow.getHeight()/2)
        
        @arrow.set(
            left: arrowX
            top: arrowY
        ).setCoords()

    activateHover: () ->
        console.log('activateHover()')
        @arc.setStroke('red')
        @arrow.setFill('red')

    deactivateHover: () ->
        @arc.setStroke('black')
        @arrow.setFill('black')

    display: () ->
        @canvas.add(@arc)
        @canvas.add(@arrow)
        
    hide: () ->
        @canvas.remove(@arc)
        @canvas.remove(@arrow)
        
    remove: ({node} = {}) ->
        @hide()
        # remove edge from node unless node itself is being destroyed
        @node.removeEdge(this) unless node == @node
        
    equals: (otherEdge) ->
        # reference otherEdge.{src,dst}Node to respect Edge type
        return (@node == otherEdge.srcNode and
                @node == otherEdge.dstNode)
    
    setDestNode: (dummy) ->
        @display()


exports = this
exports.Edge = Edge
exports.SelfEdge = SelfEdge
