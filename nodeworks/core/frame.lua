local path = (...):gsub("frame", "")

---@module "misc"
local misc = require(path .. "misc")
---@module "vec2"
local vec2 = require(path .. "vec2")
---@module "spatial"
local spatial = require(path .. "spatial")

---@class frame
---@field image love.Image
---@field quad love.Quad
---@field slices table
---@field slice_data table
---@field offset vec2
---@field dt number
local frame = misc.class()

function frame:__tostring()
    local x, y, w, h = self:get_view_port()
    local dt = self:get_dt()
    return string.format(
        "Frame(%.1f, %.1f, %.1f, %.1f, %1.2f ms)", x, y, w, h, dt * 1000
    )
end

---@param image love.Image Love2D image
---@param slices table Table of spatials
---@param quad love.Quad Love2D quad
---@param dt number
---@param slice_data table
---@param offset vec2 Offset
---@return frame
local function new(image, slices, quad, dt, slice_data, offset)
    local this = {}
    this.image = image
    this.quad = quad
    this.slices = slices
    this.dt = dt
    this.slice_data = slice_data or {}
    this.offset = offset or vec2(0, 0)
    return setmetatable(this, frame)
end

frame.new = new

function frame:copy()
    return new(self.image, self.slices, self.quad, self.dt, self.slice_data, self.offset)
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

function frame:get_view_port()
    if not self.quad then return 0, 0, 0, 0 end

    return self.quad:getViewport()
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
    local c = frame.slice_to_pos(origin)
    if self.quad then
        love.graphics.draw(
            self.image, self.quad, x, y, r, sx, sy,
            -self.offset.x + c.x, -self.offset.y + c.y
        )
    else
        love.graphics.draw(
            self.image, x, y, r, sx, sy,
            -self.offset.x + c.x, -self.offset.y + c.y
        )
    end
end

---@param slice Spatial
function frame.slice_to_pos(slice)
    return slice:center()
end

function frame:get_slice(slice_key, origin_key)
    origin_key = origin_key or "body"
    local origin_slice = self.slices[origin_key] or spatial()
    local slice = self.slices[slice_key]
    if not slice then return end
    local p = frame.slice_to_pos(origin_slice)
    return slice:move(-p.x, -p.y)
end

return frame