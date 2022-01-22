local style = {}
style.__index = {}

function style:push(next_style)
    table.insert(self, next_style)
    return self
end

function style:pop()
    table.remove(self)
    return self
end

function style:peek() return self[self:size()] end

function style:size() return #self end

function style:read(key)
    for i = self:size(), 1, -1 do
        local s = self[i]
        local v = s[key]
        if v then return v end
    end
end

return function()
    return setmetatable({}, style)
end
