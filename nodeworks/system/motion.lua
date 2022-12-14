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

    return nw.system.collision(self.world):move(entity, v.x * dt, v.y * dt)
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

    colinfo.ecs_world:set(nw.component.velocity, colinfo.item, vx, vy)
end

function Motion.observables(ctx)
    return {
        update = ctx:listen("update"):collect(),
        collision = ctx:listen("collision"):collect()
    }
end

function Motion.handle_observables(ctx, obs, ecs_world, ...)
    if not ecs_world then return end

    for _, dt in ipairs(obs.update:pop()) do
        Motion.from_ctx(ctx):update(dt, ecs_world)
    end

    for _, colinfo in ipairs(obs.collision:pop()) do
        Motion.from_ctx(ctx):on_collision(colinfo)
    end

    return Motion.handle_observables(obs, ...)
end

local default_instace = Motion.create()

local actions = {}

local function update_velocity(info, entity, dt)
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

local function update_position(info, entity, dt)
    local v = entity:get(nw.component.velocity)
    local p = entity:get(nw.component.position)

    if not p or not v then return end

    info:action(nw.system.collision().action.move, v.x * dt, v.y * dt)
end

function actions.update(info, state, dt)
    for id, _ in pairs(entities) do
        local e = ecs_world:entity(id)
        update_velocity(info, e, dt)
        update_position(info, e, dt)
    end
end

function Motion.from_ctx(ctx)
    if not ctx then return default_instace end
    local world = ctx.world or ctx
    if not world[Motion] then world[Motion] = Motion.create(world) end
    return world[Motion]
end

return Motion.from_ctx
