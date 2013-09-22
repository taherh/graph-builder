# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# graph-builder.coffee
#

Keys =
    SPACE: " ".charCodeAt(0)
    DEL: 46
    BACKSPACE: 8

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
        ).setCoords()
        
        @arrow.set(
            left: x2
            top: y2
            angle: util.toDeg(angle)+90
        ).setCoords()

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
        
        grp = new fabric.Group([circle, id_text],
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
        
    setActive: ->
        @bringToFront()
        
    unsetActive: ->
        
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
        return @uiElt.item(0).getRadiusX()
    
    bringToFront: ->
        @uiElt.bringToFront()
        
    outdegree: ->
        return @edges.length
    
    updateEdges: (node) ->
        edge.update() for edge in @edges

class GraphBuilder
    canvas: null
    graph: null
    activeEdge: null
    currActiveNode: null
    
    constructor: (@WIDTH, @HEIGHT, @RADIUS) ->
        Node.RADIUS = RADIUS
        @graph = new Graph()
        
        @canvas = new fabric.Canvas('canvas')
        @canvas.setWidth(@WIDTH)
        @canvas.setHeight(@HEIGHT)
        @canvas.setBackgroundColor("rgb(150,150,150)")
        
        @canvas.renderAll()
    
    setupHandlers: ->
        # setup dom handlers for control buttons
        $('#newnode').on('click', () => @addNode(20, 20))
        $('#delete').on('click', @handleDelete)
        $('#clear').on('click', @handleClearGraph)
        
        # setup dom handlers for canvas
        $('body').on('keydown', @handleKeyDown)
        
        # setup fabric canvas ui handlers
        @canvas.on('selection:created', @handleSelectionCreated)
        @canvas.on('object:added', @handleAdded)
        @canvas.on('mouse:down', @handleMouseDown)
        @canvas.on('object:moving', @handleMoving)
        
        # setup custom handlers to listen to GraphBuilder events
        # and update graph model accordingly
        @canvas.on('gb:new-node', (evt) =>
            @graph.addNode(evt.nodeId)
        )
        @canvas.on('gb:new-edge', (evt) =>
            @graph.addEdge([evt.srcNode, evt.dstNode])
        )
        @canvas.on('gb:del-node', (evt) =>
            @graph.delNode(evt.nodeId)
        )
        @canvas.on('gb:del-edge', (evt) =>
            @graph.delEdge([evt.x, evt.y])
        )
        
        @canvas.on('gb:new-node', @updateMatrix)
        @canvas.on('gb:new-edge', @updateMatrix)
        @canvas.on('gb:del-node', @updateMatrix)
        @canvas.on('gb:del-edge', @updateMatrix)
        @canvas.on('gb:clear', @updateMatrix)

    _idCtr: 0
    makeNode: (left, top) ->
        return new Node(@_idCtr++, left, top)
    
    # todo: don't add duplicate edges
    completeEdge: (edge, dstNode) ->
        edge.setDestNode(dstNode)
        edge.srcNode.edges.push(edge)
        dstNode.edges.push(edge)
        edge.update()
        
        @canvas.trigger('gb:new-edge', {
                                srcNode: edge.srcNode.id
                                dstNode: edge.dstNode.id
                            }
                        )
        

    handleMouseDown: (evt) =>
        console.log('mouse:down')

        if evt.e.shiftKey
            @cancelActiveEdge()
            @addNode(evt.e.offsetX, evt.e.offsetY)
            return

        if not evt.target?._node?
            @cancelActiveEdge()
            return true
        
        node = evt.target._node
        
        @setActiveNode(node)

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

    # add new node to graph
    addNode: (x, y) =>
        node = @makeNode(x, y)
        node.addTo(@canvas)
        
        @canvas.trigger('gb:new-node', { nodeId: node.id })

    # delete an edge or node
    handleDelete: (evt) =>
        @cancelActiveEdge()
        # todo
        
    # clear the graph
    handleClearGraph: (evt) =>
        @cancelActiveEdge()
        @canvas.clear()
        @graph.clear()
        @canvas.trigger('gb:clear')
        @_idCtr = 0
    
    # handle keydown events
    handleKeyDown: (e) =>
        console.log('keydown')
        switch e.which
            when Keys.SPACE
                @cancelActiveEdge()
            when Keys.DEL, Keys.BACKSPACE
                @cancelActiveEdge()
#                @deleteSelectedNodes()  # todo

        return false

    # when user selects a set of nodes, don't show resize controls
    handleSelectionCreated: (evt) =>
        console.log("handleSelectionCreated()")
        @canvas.getActiveGroup().hasControls = false
        
    handleAdded: (evt) =>
        
    cancelActiveEdge: ->
        if @activeEdge
            @activeEdge.removeFrom(@canvas)
            @canvas.off('mouse:move')
            @activeEdge = null
    
    setActiveNode: (node) ->
        if @currActiveNode?
            @currActiveNode.unsetActive()

        node.setActive()
        @currActiveNode = node        

    handleMoving: (evt) =>
        # if an object is being dragged, end the edge drawing mode
        @cancelActiveEdge()

        target = evt.target
        
        # redraw edges
        if target.type is 'group'
            if target._node?  # it's a single node
                target._node.updateEdges()
            else  # otherwise it's a group selection of nodes
                target.forEachObject((obj) =>
                    obj._node?.updateEdges()
                )

        # keep target within bounds of canvas
        if target.getLeft() > @WIDTH then target.setLeft(@WIDTH)
        if target.getTop() > @HEIGHT then target.setTop(@HEIGHT)
        if target.getLeft() < 0 then target.setLeft(0)
        if target.getTop() < 0 then target.setTop(0)
            
        @canvas.renderAll()
            

    # bound to 'mouse:move' only when there's an active edge being drawn
    handleMouseMoved: (evt) =>
        ptr = @canvas.getPointer(evt.e)
        @activeEdge.setDestPos(ptr)
        @canvas.renderAll()

    updateMatrix: () =>
        console.log('updating matrix')
        matrix_text = @graph.matrixAsText()
        $('#matrix').text(matrix_text)
        $('#matrix_download').attr('download', "matrix.dat").
                              attr('title', "matrix.dat").
                              attr('href',
                                    'data:text/plain;charset=utf-8,' +
                                        encodeURIComponent(matrix_text))

# Export GraphBuilder
exports = this
exports.GraphBuilder = GraphBuilder

    
