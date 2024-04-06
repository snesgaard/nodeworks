---@module "vec2"
local vec2 = require "nodeworks.core.vec2"

local component = {}

--- TIME

---@param t number|nil
---@return number
function component.time(t) return t or 0 end


---@param duration number
---@param init_time number|nil
function component.timer(duration, init_time)
    return {
        duration = duration,
        time = init_time
    }
end

function component.die_on_timer_done() return true end

--- COLLISION

---@param hitbox Spatial
function component.hitbox(hitbox) return hitbox end

---@param x number
---@param y number
function component.position(x, y) return vec2(x, y) end

---@param m boolean|nil
function component.mirror(m)
    if m == nil then return true end
    return m
end

return component