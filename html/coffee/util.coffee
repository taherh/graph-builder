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
    list.splice(list.indexOf(obj), 1)
