local draw_stack = {}
draw_stack.__index = draw_stack

function draw_stack.create()
    local this = {}
    this._draws = list()
    this._stack = list()
    this._last_frame = nil
    this._x = 0
    this._y = 0
    this._r = 0
    this._sx = 0
    this._sy = 0
    this = setmetatable(this, draw_stack)
    return this:reset()
end

function draw_stack:reset(x, y, r, sx, sy)
    self._x = x or 0
    self._y = y or 0
    self._r = r or 0
    self._sx = sx or 2
    self._sy = sy or 2
    return self
end

function draw_stack:clear(...)
    self._stack = list()
    self._last_frame = nil
    self._draws = list()
    return self:reset(...)
end

function draw_stack:unpack(x, y)
    x = x or 0
    y = y or 0
    return self._x + x, self._y + y, self._r, self._sx, self._sy
end

function draw_stack:submit_frame(frame, x, y)
    local function action(x, y, r, sx, sy)
        frame:draw(x, y, r, sx, sy)
    end
    self._draws[#self._draws + 1] = {action, self:unpack(x, y)}
end

function draw_stack:submit_func(func, opt, x, y, w, h)
    local function action(x, y, w, h, opt)
        func(x, y, w, h, opt)
    end

    self._draws[#self._draws + 1] = {action, x, y, w, h, opt}
end

function draw_stack:draw(dx, dy)
    dx = dx or 0
    dy = dy or 0

    local function perform_draw(action, x, y, ...)
        action(x + dx, y + dy, ...)
    end

    for _, d in ipairs(self._draws) do
        gfx.setColor(1, 1, 1)
        perform_draw(unpack(d))
    end

    return self
end

function draw_stack:push()
    self._stack[#self._stack + 1] = {self._last_frame, self:unpack()}
    return self
end

function draw_stack:stack(frame, ...)
    _, self._x, self._y = self:with(frame, ...)
    self._last_frame = frame
    return self
end

function draw_stack:pop()
    if #self._stack <= 0 then return end

    local s = self._stack:tail()
    self._stack[#self._stack] = nil

    self._last_frame, self._x, self._y, self._r, self._sx, self._sy = unpack(s)

    return self
end

function draw_stack:with(frame, link, other_link, align, valign)
    other_link = other_link or link
    align = align or "left"
    valign = valign or "top"

    local function get_link(frame, link)
        if not link or not frame or not frame.slices[link] then
            return spatial()
        else
            return frame.slices[link]
        end
    end

    local pre_link = get_link(self._last_frame, link)
    local cur_link = get_link(frame, other_link)

    pre_link = pre_link:move(self._x, self._y)
    cur_link = cur_link:move(self._x, self._y)
    local linked = cur_link
        :yalign(pre_link, valign, valign)
        :xalign(pre_link, align, align)

    local dx = self._sx * (linked.x - cur_link.x)
    local dy = self._sy * (linked.y - cur_link.y)

    self:submit_frame(frame, dx, dy)

    return self, self._x + dx, self._y + dy
end

function draw_stack:within(func, link, opt)
    opt = opt or {}
    if not self._last_frame then
        log.warn("No frame pushed")
        return self
    end

    local link_spatial = self._last_frame.slices[link]

    if not link_spatial then
        log.warn("Link <%s> not found", link)
        return self
    end

    link_spatial = link_spatial
        :scale(self._sx, self._sy)
        :move(self._x, self._y)

    self:submit_func(func, opt, link_spatial:unpack())
    return self
end

function draw_stack:label(link, opt)
end

function draw_stack:bar(link, opt)

end

return draw_stack
