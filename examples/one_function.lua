local nw = require "nodeworks"

local function draw_rectangle(data)
    local x, y = data.x or 0, data.y or 0
    gfx.rectangle("fill", x, y, 100, 100)
end

local function change_system(ctx)
    for _, events in ipairs(ctx:read_event("keypressed")) do
        local key = unpack(events)
        if key == "space" then return true end
    end
end

local function handle_mouse(ctx, rect)
    for _, event in ipairs(ctx:read_event("mousepressed")) do
        rect.x, rect.y = unpack(event)
    end
end

local function system_b(ctx)
    ctx.rect_b = ctx.rect_b or {x=100, y=100}

    ctx.layer("gui"):push()
    ctx.layer("gui"):add(draw_rectangle, ctx.rect_b)
    while ctx.alive and not change_system(ctx) do
        handle_mouse(ctx, ctx.rect_b)
        coroutine.yield()
    end
    ctx.layer("gui"):pop()
end

local function system_a(ctx)
    ctx.rect_a = ctx.rect_a or {x=0, y=0}

    ctx.layer("gui"):add(draw_rectangle, ctx.rect_a)
    while ctx.alive do
        handle_mouse(ctx, ctx.rect_a)
        if change_system(ctx) then system_b(ctx) end
        coroutine.yield()
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
    world:emit("update", dt):resolve()
end

function love.draw()
    world:draw("gui")
    --world:emit("draw"):resolve()
end
