# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# graph-builder.coffee
#

Keys =
    SPACE: " ".charCodeAt(0)

class Edge
    srcNode: null
    dstNode: null
    
    value: null
    
    # visual components of an edge
    line: null
    arrow: null
    
    constructor: (srcNode) ->
        @srcNode = srcNode

        @line = new fabric.Line([srcNode.getLeft(), srcNode.getTop(),
                                 srcNode.getLeft(), srcNode.getTop()],
            stroke: 'black'
            strokeWidth: 3
        )
        @line.selectable = false

        @arrow = new fabric.Triangle(
                width: 15
                height: 20
                visible: false
            )
        @arrow.selectable = false
        
    setDestNode: (dstNode) ->
        @dstNode = dstNode
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
        
        @line.set(
            x1: x1
            y1: y1
            x2: x2
            y2: y2
        )
        
        @arrow.set(
            left: x2
            top: y2
            angle: util.toDeg(angle)+90
        )

    addTo: (canvas) ->
        canvas.add(@line)
        canvas.add(@arrow)
        
    removeFrom: (canvas) ->
        canvas.remove(@line)
        canvas.remove(@arrow)
        
class Node
    id: null
    edges: null
    
    value: null  # value determines node's graphical diameter
    
    # visual object for node (fabric Group)
    uiElt: null
    
    constructor: (id, left, top) ->
        @id = id
        @edges = []
        @value = 1
        
        circle = new fabric.Circle(
            strokeWidth: 1
            radius: @value * Node.RADIUS
            fill: 'green'
            stroke: 'black'
        )
        id_text = new fabric.Text(id.toString(),
            fontSize: 30
        )
        
        grp = new fabric.Group([id_text, circle],
            left: left
            top: top
        )

        grp.hasControls = grp.hasBorders = false
        grp._node = this

        @uiElt = grp
        
    addTo: (canvas) ->
        canvas.add(@uiElt)
        
    removeFrom: (canvas) ->
        canvas.remove(@uiElt)
        
    getLeft: () ->
        grp = gGraphBuilder.canvas.getActiveGroup()
        if grp?.contains(@uiElt)
            return grp.getLeft() + @uiElt.getLeft()
        else
            return @uiElt.getLeft()

    getTop: () ->
        grp = gGraphBuilder.canvas.getActiveGroup()
        if grp?.contains(@uiElt)
            return grp.getTop() + @uiElt.getTop()
        else
            return @uiElt.getTop()

    setLeft: (val) ->
        @uiElt.set({left: val})    

    setTop: (val) ->
        @uiElt.set({top: val})        
    
    radius: () ->
        return @uiElt.item(1).getRadiusX()
    
    bringToFront: ->
        @uiElt.bringToFront()
        
    outdegree: ->
        return @edges.length
    
    updateEdges: (node) ->
        edge.update() for edge in @edges

class GraphBuilder
    canvas: null
    activeEdge: null
    
    constructor: (@WIDTH, @HEIGHT, @RADIUS) ->
        Node.RADIUS = RADIUS
        
        @canvas = new fabric.Canvas('canvas')
        @canvas.setWidth(@WIDTH)
        @canvas.setHeight(@HEIGHT)
        @canvas.setBackgroundColor("rgb(150,150,150)")
        
        @canvas.renderAll()
    
    setupHandlers: ->
        # setup dom handlers for control buttons
        $('#newnode').on('click', () => @addNode(20, 20))
        $('#clear').on('click', @handleClearGraph)
        
        # setup dom handlers for canvas
        $('body').on('keydown', @handleKeyDown)
        
        # setup canvas handlers
        @canvas.on('selection:created', @handleSelectionCreated)
        @canvas.on('object:added', @handleAdded)
        @canvas.on('object:selected', @handleSelected)
        @canvas.on('mouse:down', @handleMouseDown)
        @canvas.on('mouse:up', () => console.log('mouse:up') )
        @canvas.on('object:moving', @handleMoving)
        
    
    _idCtr: 0
    makeNode: (left, top) ->
        return new Node(@_idCtr++, left, top)
    
    # todo: don't add duplicate edges
    completeEdge: (edge, dstNode) ->
        edge.setDestNode(dstNode)
        edge.srcNode.edges.push(edge)
        dstNode.edges.push(edge)
        edge.update()

    # add node to graph if corresponding keystate is on
    handleMouseDown: (evt) =>
        console.log('mouse:down')
        if evt.e.shiftKey
            @cancelActiveEdge()
            @addNode(evt.e.offsetX, evt.e.offsetY)
            
    # add new node to graph
    addNode: (x, y) =>
        node = @makeNode(x, y)
        node.addTo(@canvas)

    # clear the graph
    handleClearGraph: (evt) =>
        @cancelActiveEdge()
        @canvas.clear()
        @_idCtr = 0
    
    # handle keydown events
    handleKeyDown: (e) =>
        switch e.which
            when Keys.SPACE
                @cancelActiveEdge()

    # when user selects a set of nodes, don't show resize controls
    handleSelectionCreated: (evt) =>
        @canvas.getActiveGroup().hasControls = false
        
    handleAdded: (evt) =>
        
    handleSelected: (evt) =>
        console.log('object:selected')

        if not evt.target._node?
            @cancelActiveEdge()
            return
        
        node = evt.target._node
        
        node.bringToFront()

        if @activeEdge
            # no self loops yet
            if @activeEdge.srcNode is node  
                @cancelActiveEdge()
                return
            
            @completeEdge(@activeEdge, node)
            @activeEdge.sendToBack()
            @canvas.off('mouse:move')
            @activeEdge = null
            @canvas.renderAll()
            
        else
            edge = new Edge(node)
            edge.addTo(@canvas)
            edge.sendBackwards()
        
            @activeEdge = edge

            @canvas.on('mouse:move', @handleMouseMoved)
        
    cancelActiveEdge: ->
        if @activeEdge
            @activeEdge.removeFrom(@canvas)
            @canvas.off('mouse:move')
            @activeEdge = null
            
    handleMoving: (evt) =>
        # if an object is being dragged, end the edge drawing mode
        @cancelActiveEdge()

        target = evt.target
        
        if target._node?
            target._node.updateEdges()
        else
            target.forEachObject((obj) =>
                obj._node?.updateEdges()
            )

        if target.getLeft() > @WIDTH then target.setLeft(@WIDTH)
        if target.getTop() > @HEIGHT then target.setTop(@HEIGHT)
        if target.getLeft() < 0 then target.setLeft(0)
        if target.getTop() < 0 then target.setTop(0)
            
        @canvas.renderAll()
            

    handleMouseMoved: (evt) =>
        ptr = @canvas.getPointer(evt.e)
        @activeEdge.setDestPos(ptr)
        @canvas.renderAll()

# Export GraphBuilder
exports = this
exports.GraphBuilder = GraphBuilder

    
