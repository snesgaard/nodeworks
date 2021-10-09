local stack = {}
stack.__index = stack

function stack.create(create, action)
    local this = {
        _action = action or identity,
        _create = create,
        _stack = list(),
        _state = create()
    }
    return setmetatable(this, stack)
end


function stack:push()
    self._stack[#self._stack + 1] = self._state
end

function stack:pop()
    if #self._stack <= 0 then return end
    local state = self._state
    self._state = self._stack:tail()
    self._stack[#self._stack] = nil
    self._action(self._state)
    return state
end

function stack:peek()
    return self._state
end

local function invoke(state, f, ...)
    return f(state, ...) or state
end

function stack:set(v)
    self._state = v or self._state
    self._action(self._state)
end

function stack:map(f, ...)
    self._state = f(self._state, ...) or self._state
    self._action(self._state)
end

function stack:clear(state)
    self._state = state or self._create()
    self._stack = list()
    self._action(self._state)
end

return stack
