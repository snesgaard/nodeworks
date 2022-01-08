local nw = require "nodeworks"

local components = {}

function components.image(image, quad)
    return {image=image, quad=quad}
end

function components.draw_args(x, y, r, sx, sy, ox, oy, kx, ky)
    return {
        x=x or 0, y=y or 0, r=r or 0, sx=sx or 1, sy=sy or 1,
        ox=ox or 0, oy=oy or 0, kx=kx or 0, ky=ky or 0,

        unpack = function(self)
            return self.x, self.y, self.r, self.sx, self.sy, self.ox, self.oy,
                self.kx, self.ky
        end
    }
end

function components.slices(slices)
    return slices or {}
end

function components.body_slice(slice_name)
    return slice_name or "body"
end

function components.mirror(value)
    if value == nil then value = false end
    return value
end

function components.visible(value)
    if value == nil then value = true end
    return value
end

function components.hidden(v)
    if v == nil then return true end
    return v
end

function components.on_frame_changed(prev_frame, next_frame)
    return {prev_frame, next_frame}
end

components.sprite = nw.ecs.assemblage(
    components.image, components.draw_args, components.body_slice,
    components.slices, components.mirror, components.visible
)


---

local timer = {}
timer.__index = timer

function timer.create(duration, time)
    duration = duration or 0
    return setmetatable({duration=duration or 0, time=time or duration}, timer)
end

function timer:update(dt)
    self.time = self.time - dt
    return self:done()
end

function timer:reset()
    self.time = self.duration
end

function timer:done()
    return self.time <= 0
end

function timer:time_left_normalized()
    return self.time / self.duration
end

function timer:finish()
    self.time = 0
end

components.timer = timer

--------------------------------------------------

local tick = {}
tick.__index = tick

function tick.create(ticks)
  return setmetatable({max=ticks, value=ticks}, tick)
end

function tick:update()
  self.value = self.value - 1
  return self.value <= 0
end

function tick:reset()
  self.value = self.max
end

components.tick = tick
---

components.tween = require(... .. ".tween")

---

function components.position(x, y)
    if type(x) == "table" then x, y = x:unpack() end
    return vec2(x, y)
end

function components.velocity(x, y) return vec2(x, y) end

function components.gravity(x, y) return vec2(x, y) end

function components.drag(k) return k end

function components.particles(...)
    return particles(...)
end

--- SPRITE ANIMATION-----------------

function components.animation_map(atlas, animation_id_from_tag)
    local animation_map = {}

    for id, tag in pairs(animation_id_from_tag) do
        animation_map[id] = atlas:get_animation(tag)
        if not animation_map[id] then
            error("Could not find animation:", tag)
        end
    end

    return animation_map
end

function components.index(i) return i or 0 end
function components.frame_sequence(s) return s or {} end
function components.animation_args(playing, once, mode, id)
    return {
        playing=playing or false,
        once=once or false,
        mode=mode or "forward",
        id=id
    }
end

components.animation_state = nw.ecs.assemblage(
    components.timer,
    components.frame_sequence,
    components.index,
    components.animation_args
)

----------------------------------------

--- COLLISSION ------------------------

function components.body() return true end

function components.oneway() return true end

function components.hitbox(x, y, w, h)
    return spatial(x, y, w, h)
end

function components.bump_world(world)
    return world
end

function components.hitbox_collection(...)
    local function init_hitbox(hitbox_data)
        local entity = ecs.entity()

        for component, args in pairs(hitbox_data) do
            entity:add(component, unpack(args))
        end

        if not entity[components.hitbox] then
            error("Hitbox must be specified!")
        end

        return entity
    end

    return List.map({...}, init_hitbox)
end

function components.tag(tag) return tag end

function components.parent(parent) return parent end

function components.collision_filter(f) return f end

function components.disable_motion(v) return v or 0 end

---------------------------------------

local action = {}
action.__index = action

function action.create(type, ...)
    if type == nil then
        error("Type must not be nil!")
    end
    return setmetatable({_type=type, _args={...}}, action)
end

function action:type() return self._type end

function action:args() return unpack(self._args) end

components.action = action

function components.root_motion() return true end

function components.input_buffer() return {} end

return components
