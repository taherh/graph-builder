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

class GraphBuilder
    canvas: null
    graph: null
    activeEdge: null
    currActiveNode: null
    deleteMode: false
    nodeList: null
    
    hoveredObj: null
    
    constructor: (@WIDTH, @HEIGHT, @RADIUS) ->
        Node.RADIUS = RADIUS
        @graph = new GraphModel()
        @nodeList = []
        
        @canvas = new fabric.Canvas('canvas')
        @canvas.setWidth(@WIDTH)
        @canvas.setHeight(@HEIGHT)
        @canvas.setBackgroundColor("rgb(150,150,150)")
        
        @_addHoverEvent(@canvas)
        
        @matrixView = new MatrixView()
        
        @canvas.renderAll()
    
    setupHandlers: ->
        # setup dom handlers for control buttons
        $('#compact').on('click', @handleCompactGraph)
        $('#clear').on('click', @handleClearGraph)
        
        # setup keyboard handlers
        $('body').on('keydown', @handleKeyDown)
        $('body').on('keyup', @handleKeyUp)
        
        # setup fabric canvas ui handlers
        @canvas.on('selection:created', @handleSelectionCreated)
        @canvas.on('mouse:down', @handleMouseDown)
        @canvas.on('object:moving', @handleMoving)
        
        @canvas.on('object:over', @handleHoverOver)
        @canvas.on('object:out', @handleHoverOut)
        
        @canvas.on(
                    'gb:new-node': @updateMatrix
                    'gb:new-edge': @updateMatrix
                    'gb:del-node': @updateMatrix
                    'gb:del-edge': @updateMatrix
                    'gb:clear':    @updateMatrix
                    'gb:compact':  @updateMatrix
                )
        
    # hooks into canvas.findTarget() to generate hover events
    # object:over and object.out
    #
    # based on http://fabricjs.com/hovering/
    _addHoverEvent: (canvas) ->
        canvas.findTarget = ((originalFn) ->
            return (args...) ->
                if this != canvas then console.log('huh?')
                target = originalFn.apply(this, args)
                if target
                    if this._hoveredTarget != target
                        this.fire('object:over', target: target)
                        target.fire('over')
                        if this._hoveredTarget
                            this.fire('object:out', target: this._hoveredTarget)
                            this._hoveredTarget.fire('out')
                        this._hoveredTarget = target
                else if this._hoveredTarget
                    this.fire('object:out', { target: this._hoveredTarget, noNewTarget: true })
                    this._hoveredTarget.fire('out', noNewTarget: true)
                    this._hoveredTarget = null
                return target
        )(canvas.findTarget)
    

     completeEdge: (edge, dstNode) ->
        edge.setDestNode(dstNode)
        edge.srcNode.addEdge(edge)
        dstNode.addEdge(edge)
        @graph.addEdge([edge.srcNode.id, edge.dstNode.id])
        @canvas.trigger('gb:new-edge',
                            srcNode: edge.srcNode.id
                            dstNode: edge.dstNode.id
                        )
        
    handleHoverOver: (evt) =>
        # pass along hover over event to corresponding node or edge if appropriate

        graphObj = evt.target?._node or evt.target?._edge or null

        
        if graphObj == null
            @hoveredObj = null
            return

        if graphObj == @hoveredObj
            return        

        @hoveredObj = graphObj

        graphObj.activateHover() if @deleteMode

        @canvas.renderAll()
    
    handleHoverOut: (evt) =>
        # pass along hover out event to corresponding node or edge if appropriate
        
        graphObj = evt.target?._node or evt.target?._edge or null

        # if we've hovered off anything, then unset @hoveredObj
        if evt.noNewTarget
            @hoveredObj = null

        if graphObj == null or graphObj == @hoveredObj
            return
        
        graphObj.deactivateHover() if @deleteMode

        @canvas.renderAll()

    handleMouseDown: (evt) =>
        # delete mode
        if @deleteMode
            graphObj = evt.target?._node or evt.target?._edge or null
            if graphObj == null then return
            @deleteGraphObj(graphObj)
            return
            
        # add node
        if evt.e.shiftKey
            @cancelActiveEdge()
            @addNode(evt.e.offsetX, evt.e.offsetY)
            return

        # empty click (cancel edge)
        if not evt.target?._node?
            @cancelActiveEdge()
            return true
        
        # add edge or complete edge
        
        node = evt.target._node
        
        @setActiveNode(node)

        if @activeEdge
            # no self loops yet
            if @activeEdge.srcNode is node  
                @cancelActiveEdge()
                return
            
            # check if this is a duplicate edge
            if @activeEdge.srcNode.hasEdge(@activeEdge.srcNode, node)
                @cancelActiveEdge()
                return

            @completeEdge(@activeEdge, node)
            @activeEdge.sendToBack()
            @canvas.off('mouse:move')
            @activeEdge = null
            @canvas.renderAll()
            
        else
            edge = new Edge(node, @canvas)
            edge.display()
            edge.sendBackwards()
        
            @activeEdge = edge

            @canvas.on('mouse:move', @handleMouseMoved)

    # add new node to graph
    addNode: (x, y) ->
        nodeId = @graph.newNode(x, y)
        node = new Node(nodeId, x, y, @canvas)
        @nodeList.push(node)
        node.display()

        @canvas.trigger('gb:new-node', { nodeId: nodeId, x: x, y: y })

    # delete a node or edge
    deleteGraphObj: (graphObj) ->
        if graphObj instanceof Node
            @deleteNode(graphObj)
        if graphObj instanceof Edge
            @deleteEdge(graphObj)

            
    deleteNode: (node) ->
        node.remove()
        @graph.delNode(node.id)
        @canvas.trigger('gb:del-node', { nodeId: node.id })
        
        @canvas.renderAll()

    deleteEdge: (edge) ->
        edge.remove()
        @graph.delEdge([edge.srcNode.id, edge.dstNode.id])
        @canvas.trigger('gb:del-edge',
                            src: edge.srcNode.id
                            dst: edge.dstNode.id
                        )
        
        @canvas.renderAll()

    # enable/disable delete mode which enables/disables hover-highlighting
    # and delete on click
    
    enableDeleteMode: ->
        return if @deleteMode
        @deleteMode = true
        @cancelActiveEdge()
        @hoveredObj?.activateHover()
        @canvas.renderAll()
        
    disableDeleteMode: ->
        return unless @deleteMode
        @deleteMode = false
        @hoveredObj?.deactivateHover()
        @hoveredObj = null
        @canvas.renderAll()
        
    # compact the node ids (e.g., if there were any deletions)
    handleCompactGraph: (e) =>
        @cancelActiveEdge()
        remap = @graph.compact()
        @canvas.trigger('gb:compact', { remap: remap })
        @canvas.renderAll()

    # clear the graph
    handleClearGraph: (e) =>
        @cancelActiveEdge()
        @graph.clear()
        @canvas.trigger('gb:clear')
        @canvas.clear()
    
    # handle keydown events
    handleKeyDown: (e) =>
        switch e.which
            when Keys.SPACE
                @cancelActiveEdge()
            when Keys.DEL
                @enableDeleteMode()

        e.preventDefault()
    
    # handle keyup events
    handleKeyUp: (e) =>
        switch e.which
            when Keys.DEL
                @disableDeleteMode()
                
        e.preventDefault()

    # when user selects a set of nodes, don't show resize controls
    handleSelectionCreated: (evt) =>
        console.log("handleSelectionCreated()")
        @canvas.getActiveGroup().hasControls = false
        
    cancelActiveEdge: ->
        if @activeEdge
            @activeEdge.hide()
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
        matrixText = @matrixView.asText(@graph)
        $('#matrix').text(matrixText)
        $('#matrix_download').attr('download', "matrix.dat")
                             .attr('title', "matrix.dat")
                             .attr('href',
                                    'data:text/plain;charset=utf-8,' +
                                        encodeURIComponent(matrixText))

# Export GraphBuilder
exports = this
exports.GraphBuilder = GraphBuilder

    
