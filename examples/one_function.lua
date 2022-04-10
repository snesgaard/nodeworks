local nw = require "nodeworks"

local function draw_card(x, y, selected)
    if selected then
        gfx.setColor(0.8, 0.4, 0.2)
    else
        gfx.setColor(1, 1, 1)
    end
    gfx.rectangle("fill", x, y, 50, 200)
    gfx.setColor(0, 0, 0)
    gfx.rectangle("line", x, y, 50, 200)
end

local function read_offset(ctx, card)
    local entity = ctx.tweens.offset[card]
    if not entity then return 0 end

    local tween = entity:get(nw.component.tween)
    return tween:value()
end

local function draw_all_cards(ctx)
    for i, card in ipairs(ctx.cards) do
        local x, y = i * 60, 20
        local offset = read_offset(ctx, card)
        draw_card(x, y + offset, card == ctx.selected)
    end

    draw_card(60, 250 + read_offset(ctx, "bottom_card"), "bottom_card" == ctx.selected)
end

local function move_card_to(ctx, card, x, y)
    return ctx:entity()
        :set(nw.component.tween)
        :set(nw.component.position)

end


local function change_selection(ctx, from, to)
    local select_offset = -10
    local tween_duration = 0.2

    if from then
        ctx.tweens.offset[from] = ctx:entity()
            :set_tag("from tween")
            :set(nw.component.tween, select_offset, 0, tween_duration)
            :set(nw.component.release_on_complete)
    end

    if to then
        ctx.tweens.offset[to] = ctx:entity()
            :set_tag("to tween")
            :set(nw.component.tween, 0, select_offset, tween_duration)
            :set(nw.component.release_on_complete)
    end
end

local function handle_keypressed(ctx, key)
    local map = {left = {}, right = {}, up = {}, down = {}}

    for i, card in ipairs(ctx.cards) do
        map.left[card] = ctx.cards[i - 1]
        map.right[card] = ctx.cards[i + 1]
        map.down[card] = "bottom_card"
    end

    -- Link ends
    map.left[ctx.cards:head()] = ctx.cards:tail()
    map.right[ctx.cards:tail()] = ctx.cards:head()

    map.left.default = ctx.cards:tail()
    map.right.default = ctx.cards:head()
    map.down.default = ctx.cards:head()
    map.up.default = "bottom_card"

    map.up.bottom_card = ctx.cards:head()

    local selected = ctx.selected or "default"

    local keymap = map[key]
    if not keymap then return end

    local next_selected = keymap[selected]

    if not next_selected then return end

    change_selection(ctx, ctx.selected, next_selected)
    ctx.selected = next_selected
end

local function point_inside(box, x, y)
    return box.x < x and x <= box.x + box.w and box.y < y and y <= box.y + box.h
end

local function handle_mousepressed(ctx, x, y, button)
    if button ~= 1 then return end

    local hitboxes = {}
    for i, card in ipairs(ctx.cards) do
        hitboxes[card] = spatial(i * 60, 20, 50, 200)
    end
    hitboxes.bottom_card = spatial(60, 250, 50, 200)

    for select, box in pairs(hitboxes) do
        if point_inside(box, x, y) then
            ctx.selected = select
            return
        end
    end
end

local function card_system(ctx)
    ctx.cards = list()
    ctx.tweens = {offset = {}}

    for i = 1, 10 do table.insert(ctx.cards, ctx:entity()) end

    while ctx.alive do
        ctx:visit_event("keypressed", handle_keypressed)
        ctx:visit_event("mousepressed", handle_mousepressed)
        ctx:visit_event("draw", draw_all_cards)
        coroutine.yield()
    end
end

function love.load()
    world = nw.ecs.world()
    world:push(nw.system.tween):push(card_system)
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
    world:emit("draw"):resolve()
end
