local nw = require "nodeworks"

local Motion = class()

function Motion.create(world)
    return setmetatable({world=world}, Motion)
end

function Motion:update(dt, ecs_world, ...)
    if not ecs_world then return end

    local entities = ecs_world:get_component_table(nw.component.position)

    for id, _ in pairs(entities) do
        local e = ecs_world:entity(id)
        self:update_velocity(e, dt)
        self:update_position(e, dt)
    end

    return self:update(dt, ...)
end

function Motion:update_velocity(entity, dt)
    local g = entity:get(nw.component.gravity)
    local d = entity:get(nw.component.drag)

    if not g and not d then return end

    local g = g or vec2()
    local d = d or 0
    local v = entity:ensure(nw.component.velocity)
    local vx = v.x + (g.x - v.x * d) * dt
    local vy = v.y + (g.y - v.y * d) * dt
    entity:set(nw.component.velocity, vx, vy)
end

function Motion:update_position(entity, dt)
    local v = entity:get(nw.component.velocity)
    local p = entity:get(nw.component.position)

    if not p or not v then return end

    return nw.system.collision(self.world):move(entity, p.x + v.x * dt, p.y + v.y * dt)
end

function Motion:on_collision(colinfo)
    local v = colinfo.ecs_world:get(nw.component.velocity, colinfo.item)

    if not v then return end
    if colinfo.type ~= "slide" and colinfo.type ~= "touch" then return end

    local vx, vy = v:unpack()
    local t = 0.9
    if colinfo.normal.y <= -t then
        vy = math.min(0, vy)
    elseif colinfo.normal.y >= t then
        vy = math.max(0, vy)
    elseif colinfo.normal.x <= -t then
        vx = math.min(0, vx)
    elseif colinfo.normal.x >= t then
        vx = math.max(0, vx)
    end

    colinfo.ecs_world:set(nw.component.velocity, colinfo.item, vx, vyq)
end

local default_instace = Motion.create()

return function(ctx)
    if not ctx then return default_instace end
    local world = ctx.world or ctx
    if not world[Motion] then world[Motion] = Motion.create(world) end
    return world[Motion]
end
