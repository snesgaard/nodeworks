local nw = require "nodeworks"

local tween_system = nw.ecs.system(nw.component.timer)

function tween_system.update(world, pool, dt)
    for _, entity in ipairs(pool) do
        local timer = entity % nw.component.timer
        timer:update(dt)
    end
end

return tween_system
