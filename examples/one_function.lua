local nw = require "nodeworks"

local function system_a(ctx)
    local yes = ctx:listen("keypressed"):collect()
    while ctx.alive do
        for _, event in ipairs(yes:peek()) do
            print(unpack(event))
        end
        ctx:yield()
    end
end

function love.load()
    world = nw.ecs.world()
    world:push(system_a)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    world:emit("keypressed", key)
end

function love.mousepressed(x, y, button)
    world:emit("mousepressed", x, y, button)
end

function love.update(dt)
    world:emit("update", dt):spin()
end

function love.draw()
    world:emit("draw"):spin()
end
