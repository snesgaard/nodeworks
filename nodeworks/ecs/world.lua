local nw = require "nodeworks"

local pool_manager = {}
pool_manager.__index = pool_manager

function pool_manager.create()
    return setmetatable(
        {
            entity_pools = {},
            component_last_changed = {},
            component_pools = {},
            pool_last_changed = {},
            last_change_index = 1,
        },
        pool_manager
    )
end

local function recursive_pool_lookup(pool, component, ...)
    if component == nil then return pool end
    pool[component] = pool[component] or nw.ecs.pool()
    return recursive_pool_lookup(pool[component], ...)
end

function pool_manager:get_entity_pool(...)
    return recursive_pool_lookup(self.entity_pools, ...)
end

function pool_manager:get_component_pool(component)
    self.component_pools[component] = self.component_pools[component] or nw.ecs.pool()
    return self.component_pools[component]
end

function pool_manager:set_updated(component)
    self.component_last_changed[component] = self.last_change_index
    self.last_change_index = self.last_change_index + 1
    return self
end

function pool_manager:notify_change(entity, component, prev_value, next_value)
    local is_there = prev_value ~= nil
    local should_be_there = next_value ~= nil

    if is_there and not should_be_there then
        self:get_component_pool(component):remove(entity)
    elseif not is_there and should_be_there then
        self:get_component_pool(component):add(entity)
    end

    if is_there ~= should_be_there then self:set_updated(component) end

    return self
end

local function find_max_changed_reduce(current_max, component, self)
    local next_changed = self.component_last_changed[component] or 0
    return math.max(current_max, next_changed)
end

local intersection = {}

function intersection.should_remove(entity, other_pools)
    for _, pool in ipairs(other_pools) do
        if not pool[entity] then return true end
    end
    return false
end

function intersection.should_add(entity, other_pools)
    for _, pool in ipairs(other_pools) do
        if not pool[entity] then return false end
    end
    return true
end

function intersection.sort_by_size(a, b)
    return #a < #b
end

function intersection.compute(target_pool, other_pools)
    -- TODO: Guard against empty other_pools
    for i = #target_pool, 1, -1 do
        local entity = target_pool[i]
        if intersection.should_remove(entity, other_pools) then
            target_pool:remove(entity)
        end
    end

    table.sort(other_pools, intersection.sort_by_size)

    for _, entity in ipairs(other_pools[1] or {}) do
        if intersection.should_add(entity, other_pools) then
            target_pool:add(entity)
        end
    end
end

function pool_manager:get_pool(...)
    local components = list(...)
    local pool = self:get_entity_pool(...)
    local pool_last_changed = self.pool_last_changed[pool] or -1
    local max_component_last_changed = components:reduce(
        find_max_changed_reduce, 0, self
    )
    local needs_update = pool_last_changed < max_component_last_changed
    if not needs_update then return pool end

    local component_pools = components:map(
        function(comp)
            return self:get_component_pool(comp)
        end
    )

    intersection.compute(pool, component_pools)

    self.pool_last_changed[pool] = max_component_last_changed

    return pool
end

local context = {}
context.__index = context

function context.create(world)
    return setmetatable(
        {
            layer=layer(),
            world=world,
            alive=true
        },
        context
    )
end

function context:yield(...)
    if self.alive then return coroutine.yield(...) end
end

function context:read_event(event_key)
    return self.world:read_event(self, event_key)
end

function context:visit_event(event_key, func)
    local events = self.world:read_event(self, event_key)
    for _, event in ipairs(events) do
        if func(self, event:unpack()) then event:consume() end
    end
end

function context:sleep(duration)
    local time_left = duration

    while self.alive and time_left > 0 do
        for _, event in ipairs(self:read_event("update")) do
            local dt = unpack(event)
            time_left = time_left - dt
        end
        coroutine.yield()
    end
end

function context:pool(...) return self.world:pool(...) end

function context:entity(...) return self.world:entity(...) end

local event = {}
event.__index = event

function event.create(...)
    return setmetatable({...}, event)
end

function event:observe(system)
    local seen_before = self[system]
    self[system] = true
    return seen_before
end

function event:consume() self.consumed = true end

function event:unpack() return unpack(self) end

local CONSTANTS = {EMPTY_LIST = {}, TERMINATE = {}}

local world = {}
world.__index = world

local function system_wrapper(system, ...)
    system(...)
    coroutine.yield(CONSTANTS.TERMINATE)
end

function world:emit(event_key, ...)
    self.events[event_key] = self.events[event_key] or {}
    table.insert(self.events[event_key], event.create(...))
    return self
end

function world:fetch_context(system) return self.context[system] end

function world:has_events()
    for key, queue in pairs(self.events) do
        if #queue > 0  then return true end
    end
    return false
end

local function filter_consumed_or_observed_event(event, reader)
    return not (event.consumed or event:observe(reader))
end

function world:read_event(reader, key)
    local event_queue = self.events[key] or CONSTANTS.EMPTY_LIST

    if not event_queue then return CONSTANTS.EMPTY_LIST end

    return List.filter(event_queue, filter_consumed_or_observed_event, reader)
end

function world:clean_events()
    for key, queue in pairs(self.events) do
        for i = #queue, 1, -1 do
            local event = queue[i]
            if event:observe(self) then table.remove(queue, i) end
        end

        if #queue == 0 then self.events[key] = nil end
    end

    return self
end

function world:push(system, ...)
    if not self.systems:add(system) then return self end

    self.args[system] = {...}
    self.context[system] = context.create(self)
    self.coroutines[system] = coroutine.create(function(...)
        return system_wrapper(system, ...)
    end)

    return self
end

function world:resolve()
    local loops = 0
    while self:clean_events():has_events() do
        for _, system in ipairs(self.systems) do
            local co = self.coroutines[system]
            local ctx = self.context[system]
            local args = self.args[system]
            if co and ctx and args then
                local ret, msg = coroutine.resume(co, ctx, unpack(args))

                if ret then
                    if msg == CONSTANTS.TERMINATE then
                        self.coroutines[system] = nil
                        self.context[system] = nil
                        self.args[system] = nil
                    end
                else
                    error(msg)
                end
            end
        end

        -- Add self as "reader" for event. This is to make sure that unobserved
        -- events still get removed eventually
        loops = loops + 1
    end

    for i = #self.systems, 1, -1 do
        local system = self.systems[i]
        local co = self.coroutines[system]
        local ctx = self.context[system]
        local args = self.args[system]
        if not co or not ctx or not args then
            self.systems:remove(system)
            self.coroutines[system] = nil
            self.context[system] = nil
            self.args[system] = nil
        end
    end

    return self
end

function world:entity()
    return nw.ecs.entity():set_world(self)
end

function world:notify_change(entity, component, prev_value, next_value)
    self.pool_manager:notify_change(entity, component, prev_value, next_value)

    if self.broadcast_change[component] then
        self:emit(component, "changed", prev_value, next_value)
    end

    return self
end

function world:pool(...) return self.pool_manager:get_pool(...) end

function world:fork(parent_system, child_system, ...)
    if self.systems[child_system] then return false end

    self:push(child_system, ...)

    self.forks[parent_system] = self.forks[parent_system] or {}
    table.insert(self.forks[parent_system], child_system)
end

function world:pop(system)
    if not self.systems[system] then return end

    local forks = self.forks[system] or {}

    for _, forked_system in ipairs(forks) do
        self:pop(forked_system)
    end

    local co = self.coroutines[system]
    local ctx = self.context[system]
    local args = self.args[system]

    ctx.alive = false
    if co and ctx then coroutine.resume(co, ctx) end

    self.systems:remove(system)
    self.coroutines[system] = nil
    self.context[system] = nil
    self.args[system] = nil

    return self
end

function world:draw(layer_key)
    for _, system in ipairs(self.systems) do
        local ctx = self.context[system]
        ctx.layer(layer_key):draw()
    end
end

return function()
    return setmetatable(
        {
            pool_manager = pool_manager.create(),
            broadcast_change = {},
            context = {},
            systems = nw.ecs.pool(),
            forks = nw.ecs.pool(),
            coroutines = {},
            args = {},
            events = {}
        },
        world
    )
end
