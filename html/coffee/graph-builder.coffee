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

        @line = new fabric.Line([srcNode.left(), srcNode.top(),
                                 srcNode.left(), srcNode.top()],
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
        [x1, y1, x2, y2] = [@srcNode.left(),
                            @srcNode.top(),
                            @dstNode.left(),
                            @dstNode.top()]
        
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
        
    left: (val) ->
        if val?
            @uiElt.set({left: val})
        else
            return @uiElt.getLeft()
        
    top: (val) ->
        if val?
            @uiElt.set({top: val})
        else
            return @uiElt.getTop()
    
    radius: () ->
        return @uiElt.item(1).getRadiusX()
    
    bringToFront: ->
        @uiElt.bringToFront()
        
    outdegree: ->
        return @edges.length
        

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
        $('#newnode').on('click', @handleNewNode)
        $('#clear').on('click', @handleClearGraph)
        
        # setup dom handlers for canvas
        $('body').on('keydown', @handleKeyDown)
        
        # setup canvas handlers
        @canvas.on('selection:created', @handleSelectionCreated)
        @canvas.on('object:added', @handleAdded)
        @canvas.on('object:selected', @handleSelected)
        @canvas.on('mouse:down', () => console.log('mouse:down') )
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

    # add new node to graph
    handleNewNode: (evt) =>
        node = @makeNode(20, 20)
        node.addTo(@canvas)

    # clear the graph
    handleClearGraph: (evt) =>
        @activeEdge = null
        @canvas.clear()
        @canvas.off('mouse:move')
    
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
            return
        
        node = evt.target._node
        
        node.bringToFront()

        if @activeEdge
            return if @activeEdge.srcNode is node  # no self loops yet
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
        
        if not evt.target._node?
            return
        
        node = evt.target._node
        
        if node.left() > @WIDTH then node.left(@WIDTH)
        if node.top() > @HEIGHT then node.top(@HEIGHT)
        if node.left() < 0 then node.left(0)
        if node.top() < 0 then node.top(0)
            
        for edge in node.edges
            edge.update()

        @canvas.renderAll()
        
    handleMouseMoved: (evt) =>
        ptr = @canvas.getPointer(evt.e)
        @activeEdge.setDestPos(ptr)
        @canvas.renderAll()
        

$ ->
    window.gGraphBuilder = new GraphBuilder(640, 480, 20)
    gGraphBuilder.setupHandlers()
    
