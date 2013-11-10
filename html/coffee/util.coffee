# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# util.coffee
#

window.util = util = {}

util.sign = (x) ->
    return if x > 0 then 1 else if x < 0 then -1 else 0

util.toRad = (degrees) ->
    return degrees * (Math.PI / 180)

util.toDeg = (radians) ->
    return radians * (180 / Math.PI)

util.getAngle = (y, x) ->
    angle = Math.atan2(y, x)
    if angle >= 0
        return angle
    else
        return angle + 2*Math.PI

util.remove = (list, obj) ->
    util.removeAt(list, list.indexOf(obj))

util.removeAt = (list, idx) ->
    list.splice(idx, 1) if idx? and idx > -1

util.find = (list, pred) ->
    for i in [0..list.length]
        if pred(list[i])
            return i
    return null