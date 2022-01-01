local function construct_set(list)
    for index, item in ipairs(list) do list[item] = index end
    return list
end

local pool = {}
pool.__index = pool

function pool.create(...) return pool.from_table{...} end

function pool.from_table(table) return setmetatable(construct_set(table), pool) end

function pool:add(...)
    local function has_all(item, ...)
        if not item then return true end
        if not self:has(item) then return false end
        return has_all(...)
    end

    if has_all(...) then return self end

    local next = {unpack(self)}

    local function add(item, ...)
        if not item then return end
        if not self:has(item) then table.insert(next, item) end
        return add(...)
    end

    add(...)

    return pool.from_table(next)
end

function pool:remove(...)
    local function has_none(item, ...)
        if not item then return true end
        if self:has(item) then return false end
        return has_none(...)
    end

    if has_none(...) then return self end

    local next = {unpack(self)}

    local function remove(item, ...)
        if not item then return end
        local index = self[item]
        if index then table.remove(next, index) end
        return remove(...)
    end

    remove(...)

    return pool.from_table(next)
end

function pool:list() return list(unpack(self)) end

function pool:foreach(f, ...)
    for _, item in ipairs(self) do f(item, ...) end
    return self
end

function pool:size() return #self end

function pool:has(item) return self[item] ~= nil end

return pool
