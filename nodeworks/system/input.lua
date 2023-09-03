local nw = require "nodeworks"
local event = nw.system.event

local input = {}

function input.keypressed(key)
    event.emit("keypressed", key)
end

function input.keyreleased(key)
    event.emit("keyreleased", key)
end

function input.is_pressed(query_key)
    for _, key in event.view("keypressed") do
        if key == query_key then return true end
    end

    return false
end

function input.get_direction_x()
    local x = 0
    if love.keyboard.isDown("left") then x = x - 1 end
    if love.keyboard.isDown("right") then x = x + 1 end
    return x
end

function input.get_direction_y()
    local y = 0
    if love.keyboard.isDown("up") then y = y - 1 end
    if love.keyboard.isDown("down") then y = y + 1 end
    return y
end

return input