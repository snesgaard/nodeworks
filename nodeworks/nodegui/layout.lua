local function shape(x, y, w, h)
    return {x=x or 0, y=y or 0, w=w or 0, h=h or 0}
end

local function clone_shape(s)
    return shape(s.x, s.y, s.w, s.h)
end

local layout = {}
layout.__index = layout

function layout.create(x, y, w, h)
    return setmetatable(
        {
            stack = {},
            shape = shape(x, y, w, h),
        },
        layout
    )
end

function layout:push()
    table.insert(self.stack, clone_shape(self.shape))
    return self
end

function layout:pop()
    if #self.stack == 0 then errorf("Stack was empty") end
    self.shape = self.stack[#self.stack]
    table.remove(self.stack)
    return self
end

function layout:size(w, h)
    self.shape.w = w or self.shape.w
    self.shape.h = h or self.shape.h
    return self
end

function layout:move(dx, dy)
    self.shape.x = self.shape.x + dx
    self.shape.y = self.shape.y + dy
    return self
end

function layout:move_to(x, y)
    self.shape.x = x
    self.shape.y = y
    return self
end

function layout:right(w, h)
    self.shape.x = self.shape.x + self.shape.w
    return self:size(w, h)
end

function layout:left(w, h)
    self:size(w, h)
    self.shape.x = self.shape.x - self.shape.w
    return self
end

function layout:up(w, h)
    self:size(w, h)
    self.shape.y = self.shape.y - self.shape.h
    return self
end

function layout:down(w, h)
    self.shape.y = self.shape.y + self.shape.h
    return self:size(w, h)
end

function layout:set(shape) self.shape = shape end

function layout:get()
    return clone_shape(self.shape)
end

function layout:peek() return self.shape end

return layout.create
