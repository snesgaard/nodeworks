local frame = {}
frame.__index = frame

function frame:__tostring()
    local x, y, w, h = self.quad:getViewport()
    local dt = self:get_dt()
    return string.format("Frame(%.1f, %.1f, %.1f, %.1f, %1.2f ms)", x, y, w, h, dt * 1000)
end

function frame.create(image, slices, quad, offset)
    local this = {}
    this.image = image
    this.quad = quad
    this.slices = slices
    this.events = dict()
    this.offset = offset or vec2(0, 0)
    this.deltas = dict{}
    this.deltas_init = dict{}
    this.slices_origin = dict{}
    return setmetatable(this, frame)
end

function frame:set_dt(dt)
    self.dt = dt
    return self
end

function frame:get_dt()
    return self.dt or 0
end

function frame:args(origin, x, y, ...)
    if type(origin) ~= "string" then
        return self:args("", origin, x, y, ...)
    elseif self.slices[origin] then
        return self.slices[origin], x, y, ...
    else
        return spatial(), x, y, ...
    end
end

function frame:draw(...)
    local origin, x, y, r, sx, sy = self:args(...)
    local c = origin:center()
    if self.quad then
        gfx.draw(
            self.image, self.quad, x, y, r, sx, sy,
            -self.offset.x + c.x, -self.offset.y + c.y
        )
    else
        gfx.draw(
            self.image, x, y, r, sx, sy,
            -self.offset.x + c.x, -self.offset.y + c.y
        )
    end
end

return frame
