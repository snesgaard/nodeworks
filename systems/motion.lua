local system = ecs.system(components.position, components.velocity)

function system:update(dt)
    for _, entity in ipairs(self.pool) do
        local g = entity[components.gravity] or components.gravity()
        local v = entity[components.velocity]
        local p = entity[components.position]

        v = v + g * dt
        p = p + v * dt

        entity:update(components.velocity, v:unpack())
        entity:update(components.position, p:unpack())
    end
end

return system
