local context = {}
context.__index = context

function context:__fetch_pool(name)
    if not self[name] then
        local pool = ecs.pool(name)
        self[name] = pool
        self.__pools[name] = pool

    end
    return self[name]
end

function context.create(world)
    return setmetatable({world = world, __pools = {}}, context)
end

local world = {}
world.__index = world
world.__default_chain = "__default_chain"

function world.create(...)
    local this = {
        __events = list(),
        __entities = list(),
        __context = dict(),
        __systems = dict(),
        __chains = dict(),
    }
    setmetatable(this, world)
    this:add_system(...)
    return this
end

function world:set_chain(key, chain)
    self.__chains[key] = chain
    return self
end

function world:chain(event_key)
    local c = self.__chains[event_key]
    return c or self.__systems
end

function world:__update_entity_system(system, entity, component, ...)
    local pools = system.__pool_filter(entity)
    local c = self:context(system)

    for pool_name, should_add in pairs(pools) do
        local pool = c:__fetch_pool(pool_name)

        if should_add then
            if pool[entity] then
                local t = type(system.on_entity_updated)
                if t == "function"
                    system.on_entity_updated(c, entity, pool, component, ...)
                elseif t == "table" then
                    local f = system.on_entity_updated[component]
                    if f then f(c, entity, pool, component, ...) end
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

    return self:add_system(...)
end

function world:systems() return self.__systems end

function world:context(system)
    local c = self.__context[system]

    if c then return c end

    self.__context[system] = context.create(self)

    return self.__context[system]
end

function world:update(entity, ...)
    if not self.__entities[entity] then
        local index = #self.__entities + 1
        self.__entities[entity] = index
        self.__entities[index] = entity
    end

    for _, system in ipairs(self.__systems) do
        self:__update_entity_system(system, entity, ...)
    end

    return self
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

    while #self.__events > 0 do
        local event = self.__events:head()
        table.remove(self.__events, 1)
        self:__invoke(unpack(event))
    end

    self.__spinning = false

    return self
end

function world:__call(key, ...)
    return self:event(key, ...):spin()
end


return world.create
