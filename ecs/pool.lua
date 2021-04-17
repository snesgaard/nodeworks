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

function pool:sort(f)
    table.sort(self, f)
    
    for i, entity in ipairs(self) do
        self[entity] = i
    end

    return self
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

function pool:update(entity, ...)
    if not entity then return self end

    local index = self[entity]
    local has = entity:has(component)

    if has and not index then
        self:add(entity)
    elseif not has and index then
        self:rmove(entity)
    end

    return self:update(...)
end

return pool.create
