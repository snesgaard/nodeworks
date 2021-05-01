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

    local index = #self + 1
    self[index] = entity
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
    local size = #self

    for i = index, size do
        local e = self[i + 1]
        if e then self[e] = i end
        self[i] = e
    end

    return true
end

return pool.create
