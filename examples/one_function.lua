local nw = require "nodeworks"

local components = {}

function components.rectangle_collection(rects) return rects end

local layer_types = {}

function layer_types.color(entity)
    local color = entity:ensure(nw.component.color, 1, 1, 1)
    gfx.setColor(color)
    gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
end

function layer_types.rectangles(layer)
    local rects = layer:ensure(components.rectangle_collection)

    for _, entity in ipairs(rects) do
        local hb = entity:get(nw.component.hitbox)
        if hb then
            gfx.setColor(entity:ensure(nw.component.color, 0.5, 0.5, 0.5))
            gfx.rectangle("fill", hb:unpack())
        end
    end
end

local function draw_layer(layer)
    local func = layer:get(nw.component.layer_type)
    if not func then return end
    func(layer)
end

local layer_ids = {
    background = {},
    rectangles = {},
    foreground = {}
}

local layer_order = {
    layer_ids.background, layer_ids.rectangles, layer_ids.foreground
}

local function system_a(ctx)
    ctx.entities = nw.ecs.entity()

    local bg_layer = ctx.entities:entity(layer_ids.background)
        :set(nw.component.layer_type, layer_types.color)
        :set(nw.component.color, 1, 0.8, 0.2)

    local rect_layer = ctx.entities:entity(layer_ids.rectangles)
        :set(nw.component.layer_type, layer_types.rectangles)
        :set(
            components.rectangle_collection,
            {
                ctx.entities:entity()
                    :set(nw.component.hitbox, 0, 0, 100, 100)
                    :set(nw.component.color, 1, 1, 1),
                ctx.entities:entity()
                    :set(nw.component.hitbox, 200, 200, 1000, 5)
                    :set(nw.component.color, 1, 0, 0),
                ctx.entities:entity()
                    :set(nw.component.hitbox, 200, 200, 5, 1000)
                    :set(nw.component.color, 0, 1, 0, 0.5)
            }
        )

    local draw = ctx:listen("draw"):collect()

    while ctx.alive do
        for _, _ in ipairs(draw:pop()) do
            draw_layer(bg_layer)
            draw_layer(rect_layer)
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
