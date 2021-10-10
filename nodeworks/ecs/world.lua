local nw = require "nodeworks"

local context = {}
context.__index = context

function context:__fetch_pool(name)
    if not self[name] then
        local pool = nw.ecs.pool(name)
        self[name] = pool
        self.__pools[name] = pool

    end
    return self[name]
end

function context.create(world, system)
    local c = setmetatable({world = world, __pools = {}}, context)

    -- Just make sure that all pools exists intially
    local pools = system.__pool_filter(nw.ecs.entity())
    for key, _ in pairs(pools) do
        c:__fetch_pool(key)
    end

    return c
end

local world = {}
world.__index = world
world.__default_chain = "__default_chain"

function world.create(systems)
    local this = {
        __events = list(),
        __entities = list(),
        __context = dict(),
        __systems = dict(),
        __chains = dict(),
        __autochains = dict()
    }
    setmetatable(this, world)
    this:add_system(unpack(systems))
    return this
end

function world:breath_first()
    self.__breath_first = true
    return self
end

function world:depth_first()
    self.__breath_first = false
    return self
end

function world:set_chain(key, chain)
    self.__chains[key] = chain
    return self
end

function world:chain(event_key)
    local c = self.__chains[event_key]
    if c then return c end
    local ac = self.__autochains[event_key]
    if ac then return ac end
    local auto_chain = {}
    for _, system in ipairs(self.__systems) do
        if system[event_key] then table.insert(auto_chain, system) end
    end
    self.__autochains[event_key] = auto_chain
    return auto_chain
end

function world:__update_entity_system(system, entity, component, ...)
    local pools = system.__pool_filter(entity)
    local c = self:context(system)
    for pool_name, should_add in pairs(pools) do
        local pool = c:__fetch_pool(pool_name)

        if should_add then
            if pool[entity] then
                local t = type(system.on_entity_updated)
                if t == "function" then
                    system.on_entity_updated(c, entity, pool, component, ...)
                elseif t == "table" then
                    local f = system.on_entity_updated[component]
                    if f then f(c, entity, pool, ...) end
                end
            elseif pool:add(entity) and system.on_entity_added then
                system.on_entity_added(c, entity, pool, component, ...)
            end
        end
        if not should_add and pool:remove(entity) and system.on_entity_removed then
            system.on_entity_removed(c, entity, pool, component, ...)
        end
    end
end

function world:add_system(system, ...)
    if not system then return self end

    table.insert(self.__systems, system)

    local context = self:context(system)

    for _, entity in ipairs(self.__entities) do
        self:__update_entity_system(system, entity)
    end

    self.__autochains = {}

    return self:add_system(...)
end

function world:systems() return self.__systems end

function world:context(system)
    local c = self.__context[system]

    if c then return c end

    self.__context[system] = context.create(self, system)

    return self.__context[system]
end

function world:update(entity, ...)
    if not self.__entities[entity] then
        local index = #self.__entities + 1
        self.__entities[entity] = index
        self.__entities[index] = entity
    end

    if self.on_component_updated then
        self.on_component_updated(entity, ...)
    end

    for _, system in ipairs(self.__systems) do
        self:__update_entity_system(system, entity, ...)
    end

    return self
end

function world:entities()
    return self.__entities
end

function world:remove(entity, ...)
    local index = self.__entities[entity]
    if not index then return self end

    table.remove(self.__entities, index)
    local size = #self.__entities
    for i = index, size do
        local e = self.__entities[i]
        self.__entities[e] = i
    end

    for _, system in ipairs(self.__systems) do
        local c = self:context(system)
        for _, pool in pairs(c.__pools) do
            if pool:remove(entity) and system.on_entity_removed then
                system.on_entity_removed(c, entity, pool, ...)
            end
        end
    end

    return self
end

function world:__invoke(key, ...)
    local chain = self:chain(key)

    if self.on_event then
        self.on_event(key, ...)
    end

    for _, system in ipairs(chain) do
        local f = system[key]
        local context = self:context(system)
        if f and f(context, ...) then
            break
        end
    end

    return self
end

function world:immediate_event(key, ...)
    return self:__invoke(key, ...)
end

function world:event(key, ...)
    table.insert(self.__events, {key, ...})
    return self
end

function world:spin()
    if self.__spinning then return self end

    self.__spinning = true

    local current_events = self.__events
    self.__events = list()

    while #current_events > 0 do
        local event = current_events:head()
        table.remove(current_events, 1)
        self:__invoke(unpack(event))

        local next_events = self.__events
        self.__events = list()

        if self.__breath_first then
            current_events = current_events + next_events
        else
            current_events = next_events + current_events
        end
    end

    self.__spinning = false

    return self
end

function world:action(key, ...)
    local args = {...}
    local chain = self:chain(key)

    for _, system in ipairs(chain) do
        local f = system[key]
        if f then
            local context = self:context(system)
            args = {f(context, unpack(args))}
        end
    end

    return unpack(args)
end

function world:__call(key, ...)
    return self:event(key, ...):spin()
end


return world.create
