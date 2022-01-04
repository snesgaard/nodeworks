local pool = {}
pool.__index = pool

function pool:__tostring()
    if self.__name then
        return string.format("pool[%s, %i]", self.__name, #self)
    else
        return string.format("pool[%i]", #self)
    end
end

function pool.create(name)
    local self = {__name=name}
    return setmetatable(self, pool)
end

function pool:add(entity)
    if self[entity] then return false end

    table.insert(self, entity)
    local index = #self
    self[entity] = index

    return true
end

function pool:sort(f)
    table.sort(self, f)

    for i, entity in ipairs(self) do
        self[entity] = i
    end

    return self
end

function pool:remove(entity)
    -- TODO optimize to sort entites by index
    if not entity then return false end

    local index = self[entity]

    if not index then return false end

    self[entity] = nil
    table.remove(self, index)

    return true
end

function pool:foreach(...)
    return List.foreach(self, ...)
end

function pool:empty()
    for _, _ in pairs(self) do return false end
    return true
end

function pool:size() return #self end

return pool.create
