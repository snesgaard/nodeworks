local nw = require "."

function love.load()
    world = ecs.world(
        nw.system.collision,
        nw.system.parenting
    )
    bump_world = bump.newWorld()
end

function love.keypressed(key, scancode, isrepeat)
    world("keypressed", key)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)
end

function love.draw()
    world("debugdraw")
    bump_debug.draw_world(bump_world)
end
