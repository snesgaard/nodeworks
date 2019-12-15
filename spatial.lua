Vec2 = vec2

local Spatial = {}
Spatial.__index = Spatial

function Spatial.__tostring(s)
    return string.format(
        'Spatial :: pos = [%f, %f], size = [%f, %f]', s.x, s.y, s.w, s.h
    )
end

function Spatial.create(x, y, w, h)
    return setmetatable(
        {x = x or 0, y = y or 0, w = w or 0, h = h or 0}, Spatial
    )
end

function Spatial.__add(s1, s2)
    return Spatial.create(
        s1.x + s2.x, s1.y + s2.y,
        s1.w + s2.w, s1.h + s2.h
    )
end

function Spatial.__sub(s1, s2)
    return Spatial.create(
        s1.x - s2.x, s1.y - s2.y,
        s1.w - s2.w, s1.h - s2.h
    )
end

function Spatial:sanitize()
    return Spatial.create(
        self.w > 0 and self.x or self.x + self.w,
        self.h > 0 and self.y or self.y + self.h,
        math.abs(self.w), math.abs(self.h)
    )
end

function Spatial:copy()
    return Spatial.create(self.x, self.y, self.w, self.h)
end

function Spatial:pos()
    return vec2(self.x, self.y)
end

function Spatial:size()
    return vec2(self.w, self.h)
end

function Spatial:set(x, y, w, h)
    -- Uility for use with stack api
    return Spatial.create(x or self.x, y or self.y, w or self.w, h or self.h)
end

function Spatial:scale(sx, sy)
    sx = sx or 1
    sy = sy or sx

    return Spatial.create(
        self.x * sx, self.y * sy, self.w * sx, self.h * sy
    )
end

function Spatial:move(x, y, align, valign)
    if align == "right" then
        x = x + self.w
    elseif align == "center" then
        x = x + self.w / 2
    end
    if valign == "bottom" then
        y = y + self.h
    elseif valign == "center" then
        y = y + self.h / 2
    end
    return Spatial.create(self.x + x, self.y + y, self.w, self.h)
end

function Spatial:right(x, y, w, h, align)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    local dy = 0
    if align == "center" then
        dy = 0.5 * (self.h - h)
    elseif align == "bottom" then
        dy = self.h - h
    end
    return Spatial.create(self.x + self.w + x, self.y + y + dy, w, h)
end

function Spatial:upright(x, y, w, h)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    return Spatial.create(self.x + self.w + x, self.y - h - y, w, h)
end

function Spatial:downright(x, y, w, h)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    return Spatial.create(self.x + self.w + x, self.y + h + y, w, h)
end

function Spatial:left(x, y, w, h, align)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    local dy = 0
    if align == "center" then
        dy = 0.5 * (self.h - h)
    elseif align == "bottom" then
        dy = self.h - h
    end
    return Spatial.create(self.x - w - x, self.y + y + dy, w, h)
end

function Spatial:upleft(x, y, w, h)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    return Spatial.create(self.x - w - x, self.y - h - y, w, h)
end

function Spatial:downleft(x, y, w, h)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    return Spatial.create(self.x - w - x, self.y + h + y, w, h)
end

function Spatial:down(x, y, w, h, align)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    local dx = 0
    if align == "center" then
        dx = 0.5 * (self.w - w)
    elseif align == "right" then
        dx = self.w - w
    end
    return Spatial.create(self.x + x + dx, self.y + self.h + y, w, h)
end

function Spatial:up(x, y, w, h, align)
    local prev = self
    x = x or 0
    y = y or 0
    w = w or self.w
    h = h or self.h
    local dx = 0
    if align == "center" then
        dx = 0.5 * (self.w - w)
    elseif align == "right" then
        dx = self.w - w
    end
    return Spatial.create(self.x + x + dx, self.y - h - y, w, h)
end

function Spatial:set_position(x, y)
    return Spatial.create(x or self.x, y or self.y, self.w, self.h)
end

function Spatial:unpack(...)
    return self.x, self.y, self.w, self.h, ...
end

function Spatial:expand(w, h, align, valign)
    if self.is_inflexible then
        return self
    end

    w = w or 0
    h = h or w
    local scale_x = {left = 0, center = 0.5, right = 1}
    local sx = scale_x[align or "center"]
    sx = sx or scale.center

    local scale_y = {top = 0, center = 0.5, bottom = 1}
    local sy = scale_y[valign] or scale_y.center

    return Spatial.create(
        self.x - w * sx, self.y - h * sy, self.w + w, self.h + h
    )
end

function Spatial:set_size(w, h)
    return Spatial.create(self.x, self.y, w or self.w, h or self.h)
end

function Spatial:corner(x, y)
    local dx = x == "right" and self.w or 0
    local dy = y == "bottom" and self.h or 0

    return vec2(self.x + dx, self.y + dy)
end

function Spatial:map(f)
    return f(self)
end

function Spatial:center()
    return vec2(self.x + self.w * 0.5, self.y + self.h * 0.5)
end

function Spatial:centerbottom()
    return vec2(self.x + self.w * 0.5, self.y + self.h)
end

function Spatial:hmirror(ox, oy)
    local dx = self.x - ox
    local x = ox - dx
    return Spatial.create(x - self.w, self.y, self.w, self.h)
end

function Spatial:xalign(src, dst_side, src_side, margin)
    local default_map = "left"
    margin = margin or 0
    local dst = self
    local side_map = {}
    function side_map.left(s)
        local x = s:unpack()
        return x
    end
    function side_map.right(s)
        local x, y, w, h = s:unpack()
        return x + w
    end
    function side_map.center(s)
        local x, y, w, h = s:unpack()
        return x + w * 0.5
    end
    local src_map = side_map[src_side or default_map] or side_map[default_map]
    local dst_map = side_map[dst_side or default_map] or side_map[default_map]
    local margin_scales = {
        ["right/left"] = -1,
        ["left/right"] = 1,
    }
    ms = margin_scales[string.format("%s/%s", dst_side, src_side)] or 0
    local dx = src_map(src) - dst_map(dst) + margin * ms
    return dst:move(dx, 0)
end

function Spatial:yalign(src, dst_side, src_side, margin)
    local default_map = "top"
    margin = margin or 0
    local dst = self
    local side_map = {}
    function side_map.top(s)
        local x, y, w, h = s:unpack()
        return y
    end
    function side_map.bottom(s)
        local x, y, w, h = s:unpack()
        return y + h
    end
    function side_map.center(s)
        local x, y, w, h = s:unpack()
        return y + h * 0.5
    end
    local src_map = side_map[src_side or default_map] or side_map[default_map]
    local dst_map = side_map[dst_side or default_map] or side_map[default_map]
    local margin_scales = {
        ["top/bottom"] = 1,
        ["bottom/top"] = -1,
    }
    ms = margin_scales[string.format("%s/%s", dst_side, src_side)] or 0
    local dy = src_map(src) - dst_map(dst) + margin * ms
    return dst:move(0, dy)
end

function Spatial:align(other, xself, xother, yself, yother)
    return self
        :xalign(other, xself, xother)
        :yalign(other, yself, yother)
end

function Spatial:commit(obj)
    obj:set_spatial(self)
    return self
end

function Spatial.is_equal(a, b)
    return a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h
end

local SpatialCollection = {}
SpatialCollection.__index = SpatialCollection

function Spatial.join(...)
    local this = {}

    local function to_border(spatial)
        local x, y, w, h = spatial:unpack()
        return {x, y, x + w, y + h}
    end
    local function merge_border(a, b)
        local ax_l, ay_l, ax_u, ay_u = unpack(a)
        local bx_l, by_l, bx_u, by_u = unpack(b)
        return {
            ax_l < bx_l and ax_l or bx_l,
            ay_l < by_l and ay_l or by_l,
            ax_u < bx_u and bx_u or ax_u,
            ay_u < by_u and by_u or ay_u,
        }
    end
    local items = List.create(...)

    local function get_border()
        local border = items:map(to_border):reduce(merge_border)
        if border then
            return Spatial.create(
                border[1], border[2], border[3] - border[1],
                border[4] - border[2]
            )
        else
            return Spatial.create()
        end
    end

    return SpatialCollection.create(get_border(), items)
end

function SpatialCollection.create(border, items)
    return setmetatable(
        {border = border, items = items, x = border.x, y = border.y},
        SpatialCollection
    )
end

function SpatialCollection:unpack()
    return self.border:unpack()
end

function SpatialCollection:commit_items(...)
    local l = list(...)

    for i, obj in ipairs(l) do
        obj:set_spatial(self.items[i])
    end

    return self
end

function SpatialCollection:commit(obj)
    obj:set_spatial(self.border)
    return self
end

function SpatialCollection:compile()
    return self.border
end

function SpatialCollection:pos()
    return self.border:pos() - vec2(self.x, self.y)
end

function SpatialCollection:size()
    return self.border:size()
end

function SpatialCollection:__tostring()
    return string.format("Joined :: %s", self.border:__tostring())
end

local wrapped_apis = {
    "move", "xalign", "yalign", "set_position"
}

for _, key in pairs(wrapped_apis) do
    SpatialCollection[key] = function(self, ...)
        local f = Spatial[key]
        local next_border = f(self.border, ...)
        local x = next_border.x - self.border.x
        local y = next_border.y - self.border.y
        local next_items = self.items:map(function(s)
            return s:move(x, y)
        end)

        return SpatialCollection.create(next_border, next_items)
    end
end

return Spatial
