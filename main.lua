require "."

echo_system = ecs.system()

function echo_system:on_collision(cols)

end

function echo_system:on_entity_destroyed(entity)
    print("destroyed", entity)
end

function love.load()
    world = ecs.world(
        echo_system,
        systems.collision,
        systems.parenting
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

    P1 = ecs.entity(world)
    P2 = ecs.entity(world, "P2"):add(components.parent, P1)
    P3 = ecs.entity(world, "P3"):add(components.parent, P1)
    P4 = ecs.entity(world, "P4"):add(components.parent, P2)

    print(systems.parenting.children(P1), systems.parenting.children(P2))
    P2:destroy()
    print(systems.parenting.children(P1))
    P1:destroy()
end

function love.keypressed(key, scancode, isrepeat)
    world("keypressed", key)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)

    local x, y, cols = world:action("move", E, 50 * dt, 50 * dt)
end

function love.draw()
    bump_debug.draw_world(bump_world)
    world("draw")
end
