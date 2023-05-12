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

return input