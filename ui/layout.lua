local Layout = {}
Layout.__index = Layout

function Layout.create(pos, margin)
    local this = {
        _pos = pos, _margin = margin, _stack = {}, _shapes
    }
    return setmetatable(this, Layout):reset(pos, margin)
end

function Layout:reset(pos, margin)
    self._pos = pos or vec2(0, 0)
    self._margin = margin or vec2(0, 0)
    self._shapes = {}
end

function Layout:margin(margin)
    if margin then
        self._margin = margin
    end
    return self._margin
end

function Layout:size()
    return (self._shapes[#self._shapes] or {})[1]
end

function Layout:next_row()
    local s = self:size()
    return self._pos + vec2(0, self._margin.y + self._last_size.y)
end

function Layout:next_col()
    return self._pos + vec2(self._margin.x + self._last_size.x, 0)
end

function Layout:push(pos)
    local s = self._stack
    s[#s + 1] = {
        self._pos, self._margin, self._shapes
    }
    return self:reset(pos, self._margin)
end

function Layout:pop()
    local s = self.__stack
    assert(#s > 0, "Nothing to pop")
    local size = self._size or vec2(0, 0)
    self._pos, self._margin, self._size = unpack(s[#s])
    s[#s] = nil
    self._size = self._size:max(size)

    return self._pos, size
end

return Layout
