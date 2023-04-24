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
    this.slice_data = dict()
    return setmetatable(this, frame)
end

function frame:copy()
    return frame.create(self.image, self.slices, self.quad, self.offset)
end

function frame:set_dt(dt)
    self.dt = dt
    return self
end

function frame:get_dt()
    return self.dt or 0
end

function frame:size()
    local x, y, w, h = self.quad:getViewport()
    return w, h
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
    local slice_to_pos = frame.slice_to_pos or Spatial.center
    local c = slice_to_pos(origin)
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

function frame:get_slice(slice_key, origin_key)
    origin_key = origin_key or "body"
    local origin_slice = self.slices[origin_key] or spatial()
    local slice = self.slices[slice_key]
    if not slice then return end
    local slice_to_pos = frame.slice_to_pos or Spatial.center
    local p = slice_to_pos(origin_slice)
    return slice:move(-p.x, -p.y)
end

return frame
