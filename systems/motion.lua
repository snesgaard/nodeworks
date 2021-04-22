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

function system:on_collision(collision_info)
    local entity = collision_info.item
    if not self.pool[entity] or collision_info.type ~= "touch" then
        return
    end

    local vx, vy = entity[components.velocity]:unpack()
    local t = 0.9
    if collision_info.normal.y <= -t then
        vy = math.min(0, vy)
    elseif collision_info.normal.y >= t then
        vy = math.max(0, vy)
    elseif collision_info.normal.x <= -t then
        vx = math.min(0, vx)
    elseif collision_info.normal.x >= t then
        vx = math.max(0, vx)
    end

    entity:update(components.velocity, vx, vy)
end

return system
