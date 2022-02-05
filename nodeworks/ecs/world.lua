local nw = require "nodeworks"

local function call_if_exists(f, ...)
    if f then return f(...) end
end

local scene_context = {}
scene_context.__index = {}

function scene_context.create(world)
    return setmetatable(
        {
            entities = nw.ecs.pool(),
            pools = {},
            dirty_entities = nw.ecs.pool(),
            world = world
        },
        scene_context
    )
end

function scene_context:singleton()
    if not self.instance then self.instance = self:entity() end

    return self.instance
end

function scene_context:entity()
    local e = nw.ecs.entity(self)
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
    local should_be_there = filter(entity) and not entity:is_dead()

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
    else not should_be_there and is_there then
        call_if_exists(filter.on_entity_removed, self, entity, past, pool)
    end
end

function scene_context:handle_dirty()
    local dirty = self.dirty_entities

    if dirty:empty() then return end

    self.dirty_entities = nw.ecs.pool()

    for filter, pool in ipairs(self.pools) do
        for _, entity in ipairs(dirty) do
            local past = entity:pop_past()
            self:entity_pool_update(filter, pool, entity, past)
        end
    end

    for _, entity in ipairs(dirty) do
        if entity:is_dead() then self.entities:remove(entity) end
    end
end

function scene_context:on_pop()
    for filter, _ in pairs(self.pools) do self:remove_pool(filter) end
end

local world = {}
world.__index = world

local implementation = {}

function implementation:push(scene, ...)
    local prev_scene = self.scene_stack:peek()
    local prev_context = self.context_stack:peek()

    if prev_scene then
        call_if_exists(prev_scene.on_obscure, prev_context)
    end

    self.scene_stack:push(scene)
    self.context_stack:push(scene_context.create(self))

    call_if_exists(scene.on_push, self.context_stack:peek(), ...)
end

function implementation:pop()
    local scene = self.scene_stack:pop()
    local context = self.context_stack:pop()

    if scene then call_if_exists(scene.on_pop, context) end
    context:on_pop()

    local scene = self.scene_stack:peek()
    local context = self.context_stack:peek()

    if scene then
        call_if_exists(scene.on_reveal, context)
    end
end

function implementation:move(...)
    self:pop()
    self:push(...)
end

function implementation:clear()
    while self.scene_stack:size() > 0 then self:pop() end
end

function implementation:invoke_event(event, ...)
    for i = scene_stack:size(), 1, -1 do
        local scene = scene_stack[i]
        local context = scene_stack[i]

        context:handle_dirty()

        for _, system in ipairs(systems) do
            local f = system[event]
            if f then
                local pool = context:register_pool(system)
                f(context, pool, ...)
            end
        end

        if call_if_exists(scene[event], ...) or call_if_exists(scene.block, event, ...) then
            return
        end
    end
end

for name, func in pairs(implementation) do
    world[name] = function(self, ...)
        self.event_queue(func, self, ...)
    end
end

return function(systems)
    return setmetatable(
        {
            systems = systems,
            scene_stack = list(),
            context_stack = list(),
            event_queue = event_queue()
        }
        world
    )
end
