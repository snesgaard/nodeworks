local pool = {}
pool.__index = pool

function pool.create(components)
    local self = {}
    self.__components = components or {}
    return setmetatable(self, pool)
end

function pool:add(entity)
    if not self:should_add(entity) then return false end
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

function pool:update(entity, ...)
    if not entity then return self end

    local index = self[entity]
    local has = entity:has(self.__components)

    if has and not index then
        self:add(entity)
    elseif not has and index then
        self:remove(entity)
    end

    return self:update(...)
end

function pool:should_add(entity)
    return entity:has(self.__components)
end

return pool.create
