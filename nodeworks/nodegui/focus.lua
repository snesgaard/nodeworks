local focus = {}
focus.__index = focus

function focus.create()
    return setmetatable({}, focus)
end

function focus:peek() return self[#self] end

function focus:size() return #self end

function focus:has(id)
    -- TODO SPeed up via caching
    for _, item in ipairs(self) do
        if item == id then return true end
    end

    return false
end

function focus:head(id)
    return self:peek() == id
end

function focus:push(id) table.insert(self, id) end

function focus:pop()
    local id = self:peek()
    table.remove(self)
    return id
end

return focus.create
