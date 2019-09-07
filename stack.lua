local stack = {}
stack.__index = stack

function stack.create(null)
    local this = {
        _null = null
        _stack = list(),
        _state = null()
    }
    return setmetatable(stack)
end


function stack:push()
    self._stack[#self._stack + 1] = self._state
end

function stack:pop()
    if #self._stack <= 0 then return end
    local state = self._state
    self._state = self._stack:tail()
    self._stack[#self._stack] = nil
    return state
end

function stack:peek()
    return self._state
end

local function invoke(state, f, ...)
    return f(state, ...) or state
end

function stack:map(f, ...)
    self._state = f(self._state, ...) or self._state
end

function stack:clear()
    self._state = self._null()
    self._stack = list()
end

return api
