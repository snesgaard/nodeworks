require "init"
components = require "components"
local ecs = require "ecs"
local animated = require "animated_sprite"

local image_draw_system

local sprite_draw_system = ecs.system(components.sprite)

function sprite_draw_system:draw()
    for _, entity in ipairs(self.pool) do
        local sprite = entity[components.sprite]
        local image = sprite[components.image]
        local args = sprite[components.draw_args]


        gfx.push()

        local transform = entity[components.transform]
        if transform then transform:push() end

        if image.image and image.quad then
            gfx.draw(
                image.image, image.quad,
                args.x, args.y, args.r, args.sx, args.sy, args.ox, args.oy
            )
        elseif image.image then
            gfx.draw(
                image.image,
                args.x, args.y, args.r, args.sx, args.sy, args.ox, args.oy
            )
        end

        gfx.pop()
    end
end

function love.load()
    world = ecs.world(sprite_draw_system, animated.system)
    local atlas = get_atlas("build/characters")
    local frame = atlas:get_frame("wizard_movement/idle")
    test_entity = ecs.entity(world)
        :add(components.position, 100, 300)
        :add(components.velocity, 20)
        :add(components.sprite)
        :add(components.transform, 200, 50, 0, 2, 2)
        :add(animated.map, atlas, {
            idle="wizard_movement/idle", run="wizard_movement/run"
        })
        :add(animated.state)

    animated.play(test_entity, "run")
end

function love.keypressed(key, scancode, isrepeat)
    event("keypressed", key)

    if key == "a" then
        animated.play(test_entity, "idle")
    end
    if key == "b" then
        animated.play(test_entity, "run")
    end
    if key == "space" then
        if animated.is_paused(test_entity) then
            animated.play(test_entity)
        else
            animated.pause(test_entity)
        end
    end

    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)
    event:spin()
end

function love.draw()
    world("draw")

    --gfx.draw(frame.image, frame.quad, 100, 100)
end
