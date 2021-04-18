require "init"

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
    world = ecs.world(
        systems.animation,
        systems.particles,
        sprite_draw_system
    )
    local atlas = get_atlas("build/characters")
    local frame = atlas:get_frame("wizard_movement/idle")
    test_entity = ecs.entity(world)
        :add(components.position, 100, 300)
        :add(components.velocity, 20)
        :add(components.sprite)
        :add(components.transform, 200, 50, 0, 2, 2)
        :add(components.animation_map, atlas, {
            idle="wizard_movement/idle", run="wizard_movement/run"
        })
        :add(components.animation_state)

    systems.animation.play(test_entity, "run", true)
end

function love.keypressed(key, scancode, isrepeat)
    event("keypressed", key)

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
