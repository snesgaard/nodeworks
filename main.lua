require "init"

local sprite_draw_system = ecs.system(components.sprite)

function sprite_draw_system:draw()
    gfx.setColor(1, 1, 1)
    for _, entity in ipairs(self.pool) do
        local sprite = entity[components.sprite]
        local image = sprite[components.image]
        local args = sprite[components.draw_args]

        gfx.push()

        local position = entity[components.position] or components.position()
        gfx.translate(position:unpack())

        local slices = sprite[components.slices]
        local body_key = sprite[components.body_slice]
        local body_slice = slices[body_key] or spatial()
        local c = body_slice:centerbottom()
        local ox, oy = args.ox + c.x, args.oy + c.y

        if image.image and image.quad then
            gfx.draw(
                image.image, image.quad,
                args.x, args.y, args.r, args.sx, args.sy, ox, oy
            )
        elseif image.image then
            gfx.draw(
                image.image,
                args.x, args.y, args.r, args.sx, args.sy, ox, oy
            )
        end

        gfx.pop()
    end
end

function love.load()
    world = ecs.world(
        systems.animation,
        systems.particles,
        systems.slice_body_update,
        systems.motion,
        systems.collision,
        sprite_draw_system
    )

    systems.collision.show()

    local atlas = get_atlas("build/characters")
    local frame = atlas:get_frame("wizard_movement/idle")
    bump_world = bump.newWorld()

    test_entity = ecs.entity(world)
        :add(components.sprite)
        :add(components.position, 200, 50)
        :add(components.velocity, 20, 0)
        :add(components.animation_map, atlas, {
            idle="wizard_movement/idle", run="wizard_movement/run"
        })
        :add(components.animation_state)
        :add(components.body, 0, 0, 50, 20)
        :add(components.bump_world, bump_world)
        :add(components.body_slice)

    test_entity2 = ecs.entity(world)
        :add(components.body, 300, 0, 50, 4000)
        :add(components.bump_world, bump_world)

    test_entity3 = ecs.entity(world)
        :add(components.position, 275, 200)
        :add(components.body, 0, 0, 50, 50)
        :add(components.bump_world, bump_world)

    systems.animation.play(test_entity, "run", true)
end

function love.keypressed(key, scancode, isrepeat)
    event("keypressed", key)

    if key == "d" then test_entity:remove() end

    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)
    event:spin()
end

function love.draw()
    gfx.scale(2, 2)
    world("draw")
    --gfx.draw(frame.image, frame.quad, 100, 100)
end
