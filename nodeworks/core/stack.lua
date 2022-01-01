local stack = {}
stack.__index = stack

function stack.create(...)
    return setmetatable({...}, stack)
end

function stack:copy() return stack.create(unpack(self)) end

function stack:push(value)
    local next_stack = self:copy()
    table.insert(next_stack, value)
    return next_stack
end

function stack:pop()
    local next_stack = self:copy()
    table.remove(next_stack)
    return next_stack
end

function stack:move(value)
    local next_stack = self:copy()
    table.remove(next_stack)
    table.insert(next_stack, value)
    return next_stack
end

function stack:peek() return self[#self] end

function stack:foreach(f, ...)
    for i = #self, 1, -1 do f(self[i], ...) end
    return self
end

function stack:size() return #self end

return stack
