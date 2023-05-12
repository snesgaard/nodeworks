local nw = require "nodeworks"
local event = nw.system.event

local particles = {}

function particles.update_once(id, p, dt)
    p:update(dt)
end

function particles.update(dt)
    for id, p in stack.view_table(nw.component.particles) do
        particles.update_once(id, p, dt)
    end
end

function particles.spin()
    for _, dt in event.view("update") do particles.update(dt) end
end

function particles.empty(id)
    local p = stack.get(nw.component.particles, id)
    if not p then return true end
    return p:getCount() == 0
end

return particles