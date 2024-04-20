---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.core.vec2"
local vec2 = require "nodeworks.core.vec2"

local camera = {}

---@param camera_id Id
function camera.get_position(camera_id) 
    return stack.get_or_default(component.position, camera_id, 0, 0)
end

---@param camera_id Id
function camera.get_scale(camera_id)
    return stack.get_or_default(component.scale, camera_id, 1, 1)
end


---@param camera_id Id
function camera.get_transform(camera_id)
    return camera.get_position(camera_id), camera.get_scale(camera_id)
end

---@param pos vec2
---@param scale vec2
---@param parallax vec2
function camera.push_transform(pos, scale, parallax)
    love.graphics.scale(scale.x, scale.y)
    love.graphics.translate(-pos.x * parallax.x, -pos.y * parallax.y)
end

---@param p1 vec2
---@param p2 vec2
function camera.should_push_transform(p1, p2)
    return p1.x ~= p2.x or p1.y ~= p2.y
end

return camera