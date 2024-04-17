---@module "vec2"
local vec2 = require "nodeworks.core.vec2"

local component = {}

local metacomponent = {}

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

---@param r number|nil
function component.rotation(r) return r or 0 end


--- GRAPHICS

---@param p love.ParticleSystem
function component.particles(p) return p end

function component.die_on_particle_empty() return true end

---@param m table<string, Video>
function component.animation_map(m) return m end

---@param video Video
---@param init_time number
---@param name string
function component.animation(video, init_time, name) 
    return {
        video = video,
        init_time = init_time,
        name = name
    } 
end

---@param f frame
function component.frame(f) return f end


local meta_is_following = {}

---@param id Id
---@return fun(): boolean
function metacomponent.is_following(id)
    meta_is_following[id] = meta_is_following[id] or function() return true end
    return meta_is_following[id]
end

---@param id Id
function component.is_following(id)
    return metacomponent.is_following(id)
end

return component