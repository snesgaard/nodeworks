local stack = {}
stack.__index = stack

function stack.create(context)
    local this = {
        _stack = list(),
        _context = context or Node.create(),
        _level_context = list()
    }
    return setmetatable(this, stack)
end

function stack:initialize(f, ...)
    f(self._context, ...)
    return self
end

function stack:keypressed(key)
    local s = self._stack:tail()
    if s and s.keypressed then
        s.keypressed(self, self._context, self._level_context:tail(), key)
    end
end

function stack:update(dt)
    if self._context then
        self._context:update(dt)
    end

    for i = 1, #self._stack do
        local s = self._stack[i]
        local l = self._level_context[i]
        if s.update then
            s.update(fsm, self._context, l, dt)
        else
            l:update(dt)
        end
    end

    return self
end

function stack:draw(...)
    if self._context then
        self._context:draw(...)
    end

    for i = 1, #self._stack do
        local s = self._stack[i]
        local l = self._level_context[i]
        if s.draw then
            s.draw(self._context, l, ...)
        else
            l:draw(...)
        end
    end

    return self
end

function stack:push(state, ...)
    local n = self._stack:tail()
    if n and n.pushed then
        n.pushed(self, self._context, self._level_context:tail(), state)
    end

    local _level_context = Node.create()

    self._stack = self._stack:insert(state)
    self._level_context = self._level_context:insert(_level_context)

    if state.enter then
        return state.enter(self, self._context, _level_context, ...)
    end
end

function stack:pop(...)
    local n = self._stack:tail()
    if n and n.exit then
        n.exit(self, self._context, self._level_context:tail())
    end
    self._tmp = dict()
    self._stack = self._stack:erase()
    self._level_context = self._level_context:erase()

    local n = self._stack:tail()

    if n and n.poped then
        return n.poped(self, self._context, self._level_context:tail(), ...)
    end
end

function stack:swap(state, ...)
    local n = self._stack:tail()
    local l = self._level_context:tail()

    if not n then
        return self:push(state, ...)
    end

    self._stack[#self._stack] = state

    if n.exit then
        n.exit(self, self._context, l)
    end

    if state.enter then
        return state.enter(self, self._context, l, ...)
    end
end

return stack
