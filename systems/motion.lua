local system = ecs.system(components.position, components.velocity, components.gravity)

local function update_entity(entity, dt)
    local disable = entity[components.disable_motion] or 0
    if disable > 0 then return end

    local v = entity[components.velocity]
    local p = entity[components.position]
    local g = entity[components.gravity]
    local d = entity[components.drag] or 0

    v = v + (g - v * d) * dt
    entity:update(components.velocity, v:unpack())

    if v.x ~= 0 or v.y ~= 0 then
        p = p + v * dt
        systems.collision.move_to(entity, p:unpack())
    end
end

function system:update(dt)
    List.foreach(self.pool, update_entity, dt)
end

function system:on_collision(collision_info)

    List.foreach(collision_info, function(info)
        if not self.pool[info.item] then return end
        if info.type ~= "touch" and info.type ~= "slide" then return end


        local vx, vy = info.item[components.velocity]:unpack()
        local t = 0.9
        if info.normal.y <= -t then
            vy = math.min(0, vy)
            vx = 0
        elseif info.normal.y >= t then
            vy = math.max(0, vy)
        elseif info.normal.x <= -t then
            vx = math.min(0, vx)
        elseif info.normal.x >= t then
            vx = math.max(0, vx)
        end

        info.item:update(components.velocity, vx, vy)
    end)
end

return system
