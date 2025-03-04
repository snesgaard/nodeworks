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

function camera.get_screen_size()
    return love.graphics.getWidth(), love.graphics.getHeight()
end

---@param pos vec2
---@param scale vec2
---@param parallax vec2
function camera.push_transform(pos, scale, parallax)
    local w, h = camera.get_screen_size()
    love.graphics.translate(w / 2, h / 2)
    love.graphics.scale(scale.x, scale.y)
    love.graphics.translate(-pos.x * parallax.x, -pos.y * parallax.y)
end

local DEFAULT_POSITION = vec2(0, 0)
local DEFAULT_SCALE = vec2(1, 1)
local DEFAULT_SCREEN_SIZE = vec2(0, 0)
local DEFAULT_PARALLAX = vec2(1, 1)

---@param maybe_pos vec2?
---@param maybe_scale vec2?
---@param maybe_screen_size vec2?
---@param maybe_parallax vec2?
---@return love.Transform
function camera.get_transform_matrix(
        maybe_pos, maybe_scale, maybe_screen_size, maybe_parallax
)
    local pos = maybe_pos or DEFAULT_POSITION
    local scale = maybe_scale or DEFAULT_SCALE
    local screen_size = maybe_screen_size or DEFAULT_SCREEN_SIZE
    local parallax = maybe_parallax or DEFAULT_PARALLAX
    local T = love.math.newTransform
    local w, h = screen_size.x, screen_size.y
    return T(w / 2, h / 2) * T(0, 0, 0, scale.x, scale.y) * T(-pos.x * parallax.x, -pos.y * parallax.y)
end

---@param p1 vec2
---@param p2 vec2
function camera.should_push_transform(p1, p2)
    return p1.x ~= p2.x or p1.y ~= p2.y
end


function camera.view_to_local(x, y, maybe_w, maybe_h)
    local w = maybe_w or love.graphics.getWidth()
    local h = maybe_h or love.graphics.getHeight()

    return x - w / 2, y - h / 2
end

return camera