# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# ui_node.coffee
#

class Node
    @name: "Node"
    
    canvas: null
    
    id: null
    edges: null
    
    value: null  # value determines node's graphical diameter
    
    # visual object for node (fabric Group)
    uiElt: null
    
    constructor: (@id, left, top) ->
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
    
    addEdge: (edge) ->
        @edges.push(edge)
    
    updateEdges: (node) ->
        edge.update() for edge in @edges
        
    activateHover: () ->
        @uiElt.item(0).setFill('red')
    
    deactivateHover: () ->
        @uiElt.item(0).setFill('green')

    display: (@canvas) ->
        @canvas.add(@uiElt)
        
    hide: () ->
        @canvas.remove(@uiElt)
        
    removeEdge: (edge) ->
        edgeEQPred = (otherEdge) -> return edge.equals(otherEdge)
        
        util.removeAt(@edges, util.find(@edges, edgeEQPred))
        
    hasEdge: (srcNode, dstNode) ->
        return _.any(@edges,
            (edge) -> srcNode == edge.srcNode and dstNode == edge.dstNode
        )

    setId: (id) ->
        @id = id
        @uiElt.item(1).setText(id.toString())

    remove: () ->
        edge.remove(node: this) for edge in @edges
        @hide()
        @uiElt.destroy()


exports = this
exports.Node = Node