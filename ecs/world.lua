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

function world:chain(event_key)
    local c = self.__chains[event_key]
    return c or self.__systems
end

function world:add_system(system, ...)
    if not system then return self end

    table.insert(self.__systems, system)

    return self:add_system(...)
end

function world:systems() return self.__systems end

function world:context(system)
    local context = self.__context[system]

    if context then return context end

    local context = {pool=ecs.pool(system.__components), world=self}
    context.pool:add(unpack(self.__entities))
    self.__context[system] = context

    return context
end

function world:update(entity)
    if not self.__entities[entity] then
        local index = #self.__entities + 1
        self.__entities[entity] = index
        self.__entities[index] = entity
    end

    for _, context in pairs(self.__context) do context.pool:update(entity) end

    return self
end

function world:remove(entity)
    local index = self.__entities[entity]
    if not index then return self end

    table.remove(self.__entities, index)
    local size = #self.__entities
    for i = index, size do
        local e = self.__entities[i]
        self.__entities[e] = i
    end

    for _, context in pairs(self.__context) do context.pool:remove(entity) end

    return self
end

function world:__invoke(key, ...)
    local chain = self:chain(key)

    for _, system in ipairs(chain) do
        local f = system[key]
        local context = self:context(system)
        if f then f(context, ...) end
    end
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
