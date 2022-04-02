local nw = require "nodeworks"

local function call_if_exists(f, ...)
    if f then return f(...) end
end

local scene_context = {}
scene_context.__index = scene_context

function scene_context.create(world)
    return setmetatable(
        {
            entities = nw.ecs.pool(),
            pools = {},
            dirty_entities = nw.ecs.pool(),
            world = world,
        },
        scene_context
    )
end

function scene_context:event(...) return self.world:event(...) end

function scene_context:__call(...) return self:event(...) end

function scene_context:invoke_event(event, ...)
    self:handle_dirty()

    for _, system in ipairs(self.world.systems) do
        local f = system[event]
        if f then
            local pool = self:register_pool(system)
            f(self, pool, ...)
        elseif system.all_event then
            local pool = self:register_pool(system)
            system.all_event(self, pool, event, ...)
        end
    end
end

function scene_context:singleton()
    if not self.instance then self.instance = self:entity() end

    return self.instance
end

function scene_context:entity(...)
    local e = nw.ecs.entity(self, ...)
    self.entities:add(e)
    return e
end

function scene_context:notify_change(entity)
    if self.entities[entity] then self.dirty_entities:add(entity) end
end

function scene_context:register_pool(filter)
    if self.pools[filter] then return self.pools[filter] end

    local pool = nw.ecs.pool()
    self.pools[filter] = pool

    for _, entity in ipairs(self.entities) do
        self:entity_pool_update(filter, pool, entity)
    end

    return pool
end

function scene_context:remove_pool(filter)
    local pool = self.pools[filter]
    self.pools[filter] = nil

    if type(filter) ~= "table" then return end

    for _, entity in ipairs(pool) do
        call_if_exists(filter.on_entity_removed, entity, {}, pool)
    end
end

local function get_filter(filter)
    if type(filter) == "table" then
        return filter.entity_filter
    elseif type(filter) == "function" then
        return filter
    else
        errorf("Unsupported type %s", type(filter))
    end
end

function scene_context:entity_pool_update(filter, pool, entity, past)
    local is_there = pool[entity]
    local f = get_filter(filter)
    local should_be_there = f(entity) and not entity:is_dead()

    if not is_there and not should_be_there then return end

    if should_be_there then
        pool:add(entity)
    else
        pool:remove(entity)
    end

    if type(filter) ~= "table" then return end

    if should_be_there and not is_there then
        call_if_exists(filter.on_entity_added, self, entity, pool)
    elseif should_be_there and is_there then
        call_if_exists(filter.on_entity_changed, self, entity, past, pool)
    elseif not should_be_there and is_there then
        call_if_exists(filter.on_entity_removed, self, entity, past, pool)
    end
end

function scene_context:handle_dirty()
    local dirty = self.dirty_entities

    if dirty:empty() then return end

    self.dirty_entities = nw.ecs.pool()

    for filter, pool in pairs(self.pools) do
        for _, entity in ipairs(dirty) do
            local past = entity:pop_past()
            self:entity_pool_update(filter, pool, entity, past)
        end
    end

    for _, entity in ipairs(dirty) do
        if entity:is_dead() then self.entities:remove(entity) end
    end
end

function scene_context:on_push(systems)
    for _, system in ipairs(systems) do
        local pool = self:register_pool(system)
        call_if_exists(system.on_pushed, self, pool)
    end
end

function scene_context:on_pop()
    -- TODO call on_poped here
    for filter, pool in pairs(self.pools) do
        self:remove_pool(filter)
        if type(filter) == "table" then
            call_if_exists(filter.on_poped, self, pool)
        end
    end
end

local world = {}
world.__index = world

function world:find(scene)
    for i = self.scene_stack:size(), 1, -1 do
        if self.scene_stack[i] == scene then return self.context_stack[i] end
    end
end

local implementation = {}

function implementation:push(scene, ...)
    local prev_scene = self.scene_stack:peek()
    local prev_context = self.context_stack:peek()

    if prev_scene then
        call_if_exists(prev_scene.on_obscure, prev_context)
    end

    self.scene_stack:push(scene)
    self.context_stack:push(scene_context.create(self))

    local context = self.context_stack:peek()

    call_if_exists(scene.on_push, context, ...)
    context:on_push(self.systems)
end

function implementation:pop(...)
    local scene = self.scene_stack:pop()
    local context = self.context_stack:pop()
    if scene then call_if_exists(scene.on_pop, context) end
    context:on_pop()

    local scene = self.scene_stack:peek()
    local context = self.context_stack:peek()

    if scene then
        call_if_exists(scene.on_reveal, context, ...)
    end
end

function implementation:move(...)
    self:pop()
    self:push(...)
end

function implementation:clear()
    while self.scene_stack:size() > 0 do self:pop() end
end

local function call_event_on_scene(scene, context, event, ...)
    if scene[event] then
        return scene[event](context, ...)
    elseif scene.all_event then
        return scene.all_event(context, event, ...)
    end
end

function implementation:event(event, ...)
    for i = self.scene_stack:size(), 1, -1 do
        local scene = self.scene_stack[i]
        local context = self.context_stack[i]

        if not call_event_on_scene(scene, context, event, ...) then
            context:invoke_event(event, ...)
        end

        local block_call = call_if_exists(scene.block_event, context, event, ...)
        if block_call then return end
    end
end

function implementation:reverse_event(event, ...)
    local limit = 1
    for i = self.scene_stack:size(), 1, -1 do
        local scene = self.scene_stack[i]
        local context = self.context_stack[i]
        limit = i
        local block_call = call_if_exists(scene.block_event, context, event, ...)
        if block_call then break end
    end

    for i = limit, self.scene_stack:size() do
        local scene = self.scene_stack[i]
        local context = self.context_stack[i]

        if scene[event] then
            scene[event](context, ...)
        elseif scene.all_event then
            scene.all_event(context, event, ...)
        else
            context:invoke_event(event, ...)
        end
    end
end

for name, func in pairs(implementation) do
    world[name] = function(self, ...)
        self.event_queue(func, self, ...)
        return self
    end
end

function world:__call(...) return self:event(...) end

return function(systems)
    return setmetatable(
        {
            systems = systems or {},
            scene_stack = stack(),
            context_stack = stack(),
            event_queue = event_queue()
        },
        world
    )
end
