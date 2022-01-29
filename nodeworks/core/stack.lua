local stack = {}
stack.__index = stack

function stack.create(...)
    return setmetatable({...}, stack)
end

function stack:copy() return stack.create(unpack(self)) end

function stack:push(value)
    table.insert(self, value)
    return self
end

function stack:pop()
    local value = self:peek()
    table.remove(self)
    return value
end

function stack:move(value)
    local v = self:pop()
    self:push(value)
    return v
end

function stack:peek() return self[#self] end

function stack:foreach(f, ...)
    for i = #self, 1, -1 do f(self[i], ...) end
    return self
end

function stack:size() return #self end

return stack
