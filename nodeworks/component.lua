---@module "vec2"
local vec2 = require "nodeworks.core.vec2"
---@module "misc"
local misc = require "nodeworks.core.misc"

local function declare_relation_component()
    local cache = misc.create_weak_key_table()
    ---@param id Id
    ---@return fun(): boolean
    return function(id)
        if id == nil then
            error("Relation was nil")
        end

        cache[id] = cache[id] or function() return true end
        return cache[id]
    end
end

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

component.is_following = declare_relation_component()

---@param l number
---@return number
function component.layer(l) return l or 0 end


---@param d string
function component.drawable(d) return d end

component.belongs_to = declare_relation_component()

return component