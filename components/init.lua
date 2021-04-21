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

components.sprite = ecs.assemblage(
    components.image, components.draw_args, components.body_slice,
    components.slices
)


---

local timer = {}
timer.__index = timer

function timer.create(duration)
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

function components.position(x, y) return vec2(x, y) end

function components.velocity(x, y) return vec2(x, y) end

function components.gravity(x, y) return vec2(x, y) end

components.transform = transform

components.particles = require(... .. ".particles")

--- SPRITE ANIMATION-----------------

function components.animation_map(atlas, animation_id_from_tag)
    local animation_map = {}

    for id, tag in pairs(animation_id_from_tag) do
        animation_map[id] = atlas:get_animation(tag)
    end

    return animation_map
end

function components.index(i) return i or 0 end
function components.frame_sequence(s) return s or {} end
function components.animation_args(playing, once, mode)
    return {
        playing=playing or false,
        once=once or false,
        mode=mode or "forward"
    }
end

components.animation_state = ecs.assemblage(
    components.timer,
    components.frame_sequence,
    components.index,
    components.animation_args
)

----------------------------------------

--- COLLISSION ------------------------

function components.body(x, y, w, h)
    return spatial(x, y, w, h)
end

function components.hitbox(x, y, w, h)
    return spatial(x, y, w, h)
end

function components.bump_world(world)
    return world
end

function components.hitbox_collection(box_map)
    return box_map or {}
end

function components.master(master) return master end

function components.tag(tag) return tag end

---------------------------------------

return components
