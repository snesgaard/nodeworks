require "math"

local vec2 = {}
vec2.__index = vec2


local function create(x, y)
    local this = {x = x or 0, y = y or 0}
    return setmetatable(this, vec2)
end


function vec2.__tostring(v)
    return string.format("[%f, %f]", v.x, v.y)
end


function vec2:__unm()
    return create(-self.x, -self.y)
end


function vec2:__add(v2)
    return create(self.x + v2.x, self.y + v2.y)
end


function vec2:__sub(v2)
    if type(v2) == "number" then
        return create(self.x - v2, self.y - v2)
    else
        return create(self.x - v2.x, self.y - v2.y)
    end
end


function vec2.__mul(v1, v2)
    if type(v1) == "table" and type(v2) == "table" then
        return create(v1.x * v2.x, v1.y * v2.y)
    elseif type(v1) == "table" then
        return create(v1.x * v2, v1.y * v2)
    else
        return create(v1 * v2.x, v1 * v2.y)
    end
end


function vec2.__div(v1, v2)
    if type(v1) == "table" and type(v2) == "table" then
        return create(v1.x / v2.x, v1.y / v2.y)
    elseif type(v1) == "table" then
        return create(v1.x / v2, v1.y / v2)
    else
        return create(v1 / v2.x, v1 / v2.y)
    end
end


function vec2.floor(v)
    return create(math.floor(v.x), math.floor(v.y))
end


function vec2.rotate(v1, a)
    local cosa, sina = math.cos(a), math.sin(a)
    local x = cosa * v1.x - sina * v1.y
    local y = sina * v1.x + cosa * v1.y
    return create(x, y)
end


function vec2.dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end


function vec2.cross(v1, v2)
    return v1.x * v2.y - v1.y * v2.x
end


function vec2.length(v1)
  return math.sqrt(v1:dot(v1))
end


function vec2.normalize(v1)
  return v1 * (1.0 / v1:length())
end

function vec2.unpack(v)
    return v.x, v.y
end

function vec2.clamp(v, low, up)
    return create(
        math.clamp(v.x, low.x, up.x), math.clamp(v.y, low.y, up.y)
    )
end

function vec2.max(v1, v2)
    if type(v2) == "number" then
        return create(math.max(v1.x, v2), math.max(v1.y, v2))
    else
        return create(math.max(v1.x, v2.x), math.max(v1.y, v2.y))
    end
end

function vec2.min(v1, v2)
    if type(v2) == "number" then
        return create(math.min(v1.x, v2), math.min(v1.y, v2))
    else
        return create(math.min(v1.x, v2.x), math.min(v1.y, v2.y))
    end
end

return create
