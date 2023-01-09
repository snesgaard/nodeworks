local nw = require "nodeworks"

local component = {}

function component.follow(leader, x, y)
    return {
        leader = leader,
        x = x or 0,
        y = y or 0
    }
end

local weak_table = {__mode = "k"}

local factory = setmetatable({}, weak_table)

function factory.follow_component(leader)
    local c = factory[leader]
    if not c then
        c = function(x, y)
            return component.follow(leader, x, y)
        end
        factory[leader] = c
    end
    return c
end

local Follow = nw.system.base()

function Follow.follow(entity, leader, x, y)
     for _, c in pairs(factory) do
         entity:remove(c)
     end

     if leader then
         local c = factory.follow_component(leader.id)
         entity:set(c, x, y)
     end
end

local function cross_filter() return "cross" end

function Follow.handle_mirror(ctx, entity, mirror, ecs_world, ...)
    if not ecs_world then return end

    local c = factory.follow_component(entity.id)

    local followers = ecs_world:get_component_table(c)

    for id, follow in pairs(followers) do
        nw.system.collision(ctx):mirror_to(ecs_world:entity(id), mirror, cross_filter)
        local pos = entity:get(nw.component.position)
        local x, y = pos.x, pos.y
        x = x + (mirror and -follow.x or follow.x)
        y = y + follow.y
        nw.system.collision(ctx):move_to(ecs_world:entity(id), x, y, cross_filter)
    end
end

function Follow.handle_moved(ctx, entity, dx, dy, ecs_world, ...)
    if not ecs_world then return end

    -- TODO only read here, dont create
    local c = factory.follow_component(entity.id)

    local followers = ecs_world:get_component_table(c)

    for id, follow in pairs(followers) do
        nw.system.collision(ctx):move(ecs_world:entity(id), dx, dy, cross_filter)
    end
end

function Follow.observables(ctx)
    return {
        moved = ctx:listen("moved"):collect(),
        mirror = ctx:listen("mirror"):collect()
    }
end

function Follow.handle_observables(ctx, obs)
    for _, args in ipairs(obs.mirror:pop()) do
        Follow.handle_mirror(ctx, unpack(args))
    end

    for _, args in ipairs(obs.moved:pop()) do
        Follow.handle_moved(ctx, unpack(args))
    end
end

return Follow.from_ctx
