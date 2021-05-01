require "."

function love.load()
    world = ecs.world(
        systems.collision
    )

    systems.collision.show()

    local tween = components.tween(vec2(100, 0), vec2(0, 100), 10):ease(ease.linear)

    print(tween:update(5))
    print(tween:update(2))
end

function love.keypressed(key, scancode, isrepeat)
    world("keypressed", key)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)
end

function love.draw()
    world("draw")
end
