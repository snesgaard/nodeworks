local nw = require "nodeworks"

local function handle_keys(ctx, key)
    local keymap = {left = -1, right = 1}

    local dir = keymap[key]

    if dir then
        ctx.index = ctx.index + dir
        print("a", ctx.index)
        return true
    end
end

function system_a(ctx)
    ctx.index = 0

    while ctx.alive do
        ctx:visit_event("keypressed", handle_keys)

        coroutine.yield()
    end
end

local function handle_keys_b(ctx, key)
    local keymap = {up = 1, down = -1}
    local dir = keymap[key]

    if dir then
        ctx.index = ctx.index + dir
        print("b", ctx.index)
        return true
    end
end

function system_b(ctx)
    ctx.index = 0
    while ctx.alive do
        ctx:visit_event("keypressed", handle_keys_b)
        coroutine.yield()
    end
end

function love.load()
    world = nw.ecs.world()
    world:push(system_a):push(system_b)

    world
        :emit("keypressed", "right")
        :resolve()
        :emit("keypressed", "left")
        :resolve()

    --love.event.quit()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    world:emit("keypressed", key)
end

function love.update(dt)
    world:emit("update", dt):resolve()
end
