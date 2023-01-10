local nw = require "nodeworks"

local component = {}

function component.follow(x, y)
    return {
        x = x or 0,
        y = y or 0
    }
end

local RelationalComponent = class()

function RelationalComponent.constructor(base_comp)
    return {
        data = setmetatable({}, {__mode = "k"}),
        base_comp = base_comp
    }
end

function RelationalComponent:get(id)
    return self.data[id]
end

function RelationalComponent:ensure(id)
    self.data[id] = self.data[id] or function(...) return self.base_comp(...) end
    return self:get(id)
end

function RelationalComponent:size()
    return Dictionary.size(self.data)
end

local Follow = nw.system.base()

Follow.follow_component = RelationalComponent.create(component.follow)

function Follow.follow(entity, leader, x, y)
    for _, c in pairs(Follow.follow_component.data) do entity:remove(c) end

    if not leader then return end
    local c = Follow.follow_component:ensure(leader.id)
    entity:set(c, x, y)
end

local function cross_filter() return "cross" end

function Follow.handle_mirror(ctx, entity, mirror, ecs_world, ...)
    if not ecs_world then return end

    local c = Follow.follow_component:get(entity.id)
    if not c then return end

    -- Dont create here, only pull check if it is there
    local followers = ecs_world:get_component_table(c)

    for id, follow in pairs(followers) do
        nw.system.collision(ctx):mirror_to(ecs_world:entity(id), mirror)
        local pos = entity:get(nw.component.position)
        local x, y = pos.x, pos.y
        x = x + (mirror and -follow.x or follow.x)
        y = y + follow.y
        nw.system.collision(ctx):move_to(ecs_world:entity(id), x, y)
    end
end

function Follow.handle_moved(ctx, entity, dx, dy, ecs_world, ...)
    if not ecs_world then return end

    -- TODO only read here, dont create
    local c = Follow.follow_component:get(entity.id)
    if not c then return end

    local followers = ecs_world:get_component_table(c)

    for id, follow in pairs(followers) do
        nw.system.collision(ctx):move(ecs_world:entity(id), dx, dy)
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
