# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# ui_edge.coffee
#

class Edge
    @name: "Edge"

    canvas: null
    
    srcNode: null
    dstNode: null
    
    value: null
    
    # visual components of an edge
    line: null
    arrow: null
    
    uiElt: null
    
    constructor: (@srcNode) ->

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
        
#        grp = new fabric.Group([@line, @arrow])
#        grp.selectable = false
#        grp._edge = this
        
#        @uiElt = grp
        
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

    display: (@canvas) ->
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


exports = this
exports.Edge = Edge
