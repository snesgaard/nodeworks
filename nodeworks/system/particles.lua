local nw = require "nodeworks"

local particle_system = nw.ecs.system(nw.component.particles)

function particle_system.update(world, pool, dt)
    for _, entity in ipairs(pool) do
        particle_system % nw.component.particles
        particle_system:update(dt)
    end
end

return particle_system
