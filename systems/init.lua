local systems = {}

systems.animation = require(... .. ".animation")

systems.slice_body_update = ecs.system(
    components.sprite, components.body, components.bump_world
)

function systems.slice_body_update:update(dt)
    local function _do_work(entity)
        local sprite = entity[components.sprite]
        local body_key = sprite[components.body_slice]
        local body_slice = sprite[components.slices][body_key]

        if not body_slice then return end

        local body = entity[components.body]
        local world = entity[components.bump_world]
        local x, y = world:getRect(entity)
        world:update(entity, x, y, body_slice.w, body_slice.h)
        local c = body_slice:centerbottom()
        entity:update(components.body, body_slice:move(-c.x, -c.y):unpack())
    end

    for _, entity in ipairs(self.pool) do
        _do_work(entity)
    end
end

systems.particles = ecs.system(components.particles)

function systems.particles:update(dt)
    for _, entity in ipairs(self.pool) do
        entity[components.particles]:update(dt)
    end
end

function systems.particles:draw()
    for _, entity in ipairs(self.pool) do
        local draw_args = entity[components.draw_args] or components.draw_args()
        local transform = entity[components.transform] or components.transform()

        gfx.push()
        transform.push()
        gfx.draw(entity[components.particles], draw_args:unpack())
        gfx.pop()
    end
end

systems.collision = require(... .. ".collision").body
systems.hitbox = require(... .. ".collision").hitbox
systems.hitbox_sprite = require(... .. ".sprite_collision").hitbox
systems.motion = require(... .. ".motion")

return systems
