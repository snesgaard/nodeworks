local pool = {}
pool.__index = pool

function pool.create(components)
    local self = {}
    self.__components = components
    return setmetatable(self, pool)
end

function pool:add(entity, ...)
    if not components then return self end
    if not entity then return self end

    if self[entity] then return self end

    if entity:has(components) then
        local index = #self + 1
        self[index] = entity
        self[entity] = index
    end

    return self:add(...)
end

function pool:remove(entity, ...)
    -- TODO optimize to sort entites by index
    if not entity then return self end

    local index = self[entity]

    if not index then return self end

    self[entity] = nil
    local size = #self

    for i = index, size do
        local e = self[i + 1]
        if e then self[e] = i end
        self[i] = e
    end

    return self:remove(...)
end

local world = {}
world.__index = world

function world.create()
    local this = {
        events = list(),
        entities = pool({}),
        pools = dict{},
        chains = dict{}
    }

    return setmetatable(this, world)
end

function world:spin()
    if self.__spinning then return end

    self.__spinning = true

    while self.event:size() > 0 do
        local event  = self.event:head()
        table.remove(self.event, 1)
        self:call_event(unpack(event))
    end

    self.__spinning = false

    return self
end

function world:event(key, args)
    local chain = self.chains[key] or {}

    for _, system in ipairs(chain) do
        local f = system[key]
        if f then args = f(self:context(system), args) or args end
    end

    return args
end

function world:__call(key, args)
    return self:event(key, args):spin()
end

function world:__create_pool(system)
    if self.pools[system] then return self end

    self.pools[system] = pool.create()

    self.pools[system]:add(unpack(self.entities))

    return self
end

function world:add_chain(key, systems)
    if self.chains[key] then return self end

    for _, system in ipairs(systems) do self:__create_pool(system) end

    self.chains[key] = systems

    return self
end

return world
