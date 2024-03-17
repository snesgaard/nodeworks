local tf = {}

function tf.transform(x, y, r, sx, sy, ox, oy)
    return love.math.newTransform(x, y, r, sx, sy, ox, oy)
end

local DEFAULT_POSITION = vec2()
local DEFAULT_SCALE = vec2(1, 1)

function tf.entity(id, mirror_override)
    local p = stack.get(nw.component.position, id) or DEFAULT_POSITION
    local r = stack.get(nw.component.rotation, id) or 0
    local sx = stack.get(nw.component.mirror, id) and -1 or 1
    local sy = 1
    return tf.transform(p.x, p.y, r, sx, sy)
end

function tf.between(from, to)
    local t_from = tf.entity(from)
    local t_to = tf.entity(to)
    return t_to * t_from:inverse()
end

function tf.transform_vec2(t, v)
    return vec2(t:transformPoint(v.x, v.y))
end

function tf.transform_velocity(t, vx, vy)
    local vx, vy = t:transformPoint(vx, vy)
    local ox, oy = t:transformPoint(0, 0)
    return vx - ox, vy - oy
end

function tf.transform_rectangle(t, x, y, w, h)
    local x1, y1 = t:transformPoint(x, y)
    local x2, y2 = t:transformPoint(x + w, y + h)

    local x = math.min(x1, x2)
    local y = math.min(y1, y2)
    local w = math.abs(x2 - x1)
    local h = math.abs(y2 - y1)

    return x, y, w, h
end

function tf.transform_origin(t)
    return t:transformPoint(0, 0)
end

return tf