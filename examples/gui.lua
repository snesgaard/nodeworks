local nw = require "nodeworks"

local function gamestate(cards)
    local gamestate = {
        draw = list(),
        hand = list(),
        discard = list()
    }

    for i = 1, cards do
        table.insert(gamestate.draw, i)
    end

    return gamestate
end

local cards = {}

function cards:init()
    return dict()
end

function cards:step(game)

end

function dot_maker.mousepressed(ctx, dots, x, y, button)
    if button == 1 then
        return dots:insert(vec2(x, y))
    elseif button == 2 then
        return dots:set(math.max(1, dots:size()), vec2(x, y))
    end
end

function love.load()
    dot_gui = gui(dot_maker)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    dot_gui:update(dt)
end

function love.mousepressed(x, y, button, isTouch)
    dot_gui:action("mousepressed", x, y, button)
end

function love.draw()
    dot_gui:draw()
end
