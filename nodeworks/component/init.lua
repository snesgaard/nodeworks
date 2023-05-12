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

function components.release_on_complete(v)
    if v == nil then return true end
    return v
end

---

local timer = {}
timer.__index = timer

function timer.create(duration, time)
    duration = duration or 0
    return setmetatable({duration=duration or 0, time=time or duration}, timer)
end

function timer:update(dt)
    if self.time > 0 then self.time = self.time - dt end
    return self:done()
end

function timer:overshoot()
    return math.max(0, -self.time)
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

function timer:normalized()
    return self:time_left_normalized()
end

function timer:inverse_normalized()
    return 1 - self:normalized()
end

function timer:finish()
    self.time = 0
    return self
end

components.timer = timer.create

function components.die_on_timer_done() return true end

function components.on_timer_done(func) return func end

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

components.tree = require(... .. ".tree")

---

function components.position(x, y)
    if type(x) == "table" then x, y = x:unpack() end
    return vec2(x, y)
end

function components.scale(sx, sy)
    if type(sx) == "table" then sx, sy = sx:unpack() end
    return vec2(sx, sy)
end

function components.rotation(r) return r end

function components.origin(ox, oy)
    if type(ox) == "table" then ox, oy = ox:unpack() end
    return vec2(ox, oy)
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

function components.animation_state(frames, once)
    return {
        frames = frames,
        time = 0,
        once = once
    }
end

----------------------------------------

--- COLLISSION ------------------------

function components.body() return true end

function components.oneway() return true end

function components.hitbox(x, y, w, h)
    if not w then return spatial(-x * 0.5, -y, x, y) end

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

function components.die_with_parent() return true end

function components.collision_filter(f) return f end

function components.disable_motion(v) return v or 0 end

---------------------------------------

local RelationalComponent = class()

function RelationalComponent.constructor(base_comp)
    return {
        data = setmetatable({}, {__mode = "k"}),
        base_comp = base_comp or function() return true end
    }
end

function RelationalComponent:get(id)
    return self.data[id]
end

function RelationalComponent:ensure(id)
    self.data[id] = self.data[id] or function(...) return self.base_comp(...) end
    return self:get(id)
end

function RelationalComponent:size()
    return Dictionary.size(self.data)
end

components.relation = RelationalComponent.create

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

-- GRAPHICS COMPONENTS --

function components.layer(layer) return layer end

function components.layer_pool() return nw.ecs.pool() end

function components.layer_type(type) return type end

function components.tiled_layer(layer) return layer end

function components.drawable(type) return type end

function components.polygon(poly) return poly end

function components.draw_mode(mode) return mode end

function components.mesh(mesh) return mesh end

function components.radius(r)  return r end

function components.segments(s) return s end

function components.rectangle(shape) return shape end

function components.quad(quad) return quad end

function components.image(image) return image end

function components.blend_mode(blend_mode) return blend_mode end

function components.color(r, g, b, a)
    if type(r) == "table" then return r end
    return  {r, g, b, a}
end

function components.frame(frame) return frame end

function components.shader(shader) return shader end

function components.shader_uniforms(uniforms) return uniforms end

function components.priority(priority) return priority or 0 end

function components.text(text) return text end

function components.font(font) return font end

function components.align(align) return align end

function components.valign(valign) return valign end

function components.flush_on_draw(do_it)
    return do_it or do_it == nil
end

function components.parallax(sx, sy) return vec2(sx or 1, sy or 1) end

----------------------

function components.input_buffer() return {} end

function components.delegate_queue() return {} end

function components.delegate_order(order) return order end

function components.pushdown_automata() return stack() end

function components.camera(slack, slack_type, max_move)
    return {
        slack = slack or 0,
        slack_type = slack_type or "box",
        max_move = max_move or 50
    }
end

function components.target(id) return id end

---

function components.task(t) return t or nw.task() end

function components.decision(d) return d end

function components.only_single_frame() return true end

function components.should_be_destroyed() return true end

function components.is_done() return true end

return components
