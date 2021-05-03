require "."

echo_system = ecs.system()

function echo_system:on_collision(cols)
    print("what")
    for _, col in ipairs(cols) do
        print(col.item[components.body], col.other[components.body])
    end
end

function love.load()
    world = ecs.world(
        echo_system,
        systems.collision
    )

    bump_world = bump.newWorld()
    bump_world2 = bump.newWorld()

    systems.collision.show()

    E = ecs.entity(world)
        :add(components.hitbox, 0, 0, 100, 100)
        :add(components.position, 300, 100)
        :add(components.bump_world, bump_world)
        :add(components.body)
        :remove(components.bump_world)
        :add(components.bump_world, bump_world)
        :add(
            components.hitbox_collection,
            {
                [components.hitbox] = {-10, -10, 20, 20},
                [components.body] = {}
            },
            {
                [components.hitbox] = {100, -10, 20, 20}
            }
        )
        :update(
            components.hitbox_collection,
            {[components.hitbox] = {-10, -10, 20, 20}}
        )

    F = ecs.entity(world)
        :add(components.body)
        :add(components.hitbox, 500, 0, 20, 700)
        :add(components.position)
        :add(components.bump_world, bump_world)

    C = ecs.entity(world)
        :add(components.body)
        :add(components.hitbox, 490, 300, 700, 20)
        :add(components.position)
        :add(components.bump_world, bump_world)
end

function love.keypressed(key, scancode, isrepeat)
    world("keypressed", key)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)

    local x, y, cols = systems.collision.move(
        world:context(systems.collision), E, 50 * dt, 50 * dt
    )
end

function love.draw()
    bump_debug.draw_world(bump_world)
    world("draw")
end
