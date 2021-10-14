local nw = require "nodeworks"

local system = nw.ecs.system(nw.component.position, nw.component.velocity, nw.component.gravity)

local function update_entity(entity, dt)
    local disable = entity[nw.component.disable_motion] or 0
    if disable > 0 then return end

    local v = entity[nw.component.velocity]
    local p = entity[nw.component.position]
    local g = entity[nw.component.gravity]
    local d = entity[nw.component.drag] or 0

    v = v + (g - v * d) * dt
    entity:update(nw.component.velocity, v:unpack())

    if v.x ~= 0 or v.y ~= 0 then
        p = p + v * dt
        nw.system.collision.move_to(entity, p:unpack())
    end
end

function system:update(dt)
    List.foreach(self.pool, update_entity, dt)
end

function system:on_collision(collision_info)

    List.foreach(collision_info, function(info)
        if not self.pool[info.item] then return end
        if info.type ~= "touch" and info.type ~= "slide" then return end


        local vx, vy = info.item[nw.component.velocity]:unpack()
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

        info.item:update(nw.component.velocity, vx, vy)
    end)
end

return system
