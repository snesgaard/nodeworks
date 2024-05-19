---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.core.vec2"
local vec2 = require "nodeworks.core.vec2"
---@module "nodeworks.component"
local component = require "nodeworks.component"

local tf = {}

---@param x number
---@param y number
---@param r number
---@param sx number
---@param sy number
---@param ox number
---@param oy number
function tf.transform(x, y, r, sx, sy, ox, oy)
    return love.math.newTransform(x, y, r, sx, sy, ox, oy)
end

local DEFAULT_POSITION = vec2(0, 0)
local DEFAULT_SCALE = vec2(1, 1)

---@param id Id
function tf.entity(id)
    local p = stack.get(component.position, id) or DEFAULT_POSITION
    local r = stack.get(component.rotation, id) or 0
    local s = stack.get(component.scale, id) or DEFAULT_SCALE
    local sx = stack.get(component.mirror, id) and -s.x or s.x
    local sy = s.y
    local ox, oy = 0, 0
    return tf.transform(p.x, p.y, r, sx, sy, ox, oy)
end

---@param from Id
---@param to Id
function tf.between(from, to)
    local t_from = tf.entity(from)
    local t_to = tf.entity(to)
    return t_to * t_from:inverse()
end

---@param t love.Transform
---@param v vec2
function tf.transform_vec2(t, v)
    return vec2(t:transformPoint(v.x, v.y))
end

---@param t love.Transform
---@param vx number
---@param vy number
function tf.transform_velocity(t, vx, vy)
    local vx, vy = t:transformPoint(vx, vy)
    local ox, oy = t:transformPoint(0, 0)
    return vx - ox, vy - oy
end

---@param t love.Transform
---@param x number
---@param y number
---@param w number
---@param h number
function tf.transform_rectangle(t, x, y, w, h)
    local x1, y1 = t:transformPoint(x, y)
    local x2, y2 = t:transformPoint(x + w, y + h)

    local x = math.min(x1, x2)
    local y = math.min(y1, y2)
    local w = math.abs(x2 - x1)
    local h = math.abs(y2 - y1)

    return x, y, w, h
end

---@param t love.Transform
function tf.transform_origin(t)
    return t:transformPoint(0, 0)
end

return tf