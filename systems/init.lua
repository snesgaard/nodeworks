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

systems.collision = require(... .. ".collision")
systems.hitbox_sprite = require(... .. ".sprite_collision").hitbox
systems.motion = require(... .. ".motion")

systems.sprite = ecs.system(components.sprite)

function systems.sprite:draw()
    gfx.setColor(1, 1, 1)
    for _, entity in ipairs(self.pool) do
        local sprite = entity[components.sprite]
        local image = sprite[components.image]
        local args = sprite[components.draw_args]

        gfx.push()

        local position = entity[components.position] or components.position()
        gfx.translate(position.x, position.y)

        local slices = sprite[components.slices]
        local body_key = sprite[components.body_slice]
        local body_slice = slices[body_key] or spatial()
        local c = body_slice:centerbottom()
        local ox, oy = args.ox + c.x, args.oy + c.y
        local sx = entity[components.mirror] and -1 or 1

        if sprite[components.visible] then
            if image.image and image.quad then
                gfx.draw(
                    image.image, image.quad,
                    args.x, args.y, args.r, sx * args.sx, args.sy, ox, oy
                )
            elseif image.image then
                gfx.draw(
                    image.image,
                    args.x, args.y, args.r, sx * args.sx, args.sy, ox, oy
                )
            end
        end

        gfx.pop()
    end
end

systems.parenting = require(... .. ".parenting")

return systems
