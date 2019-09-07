local color = {}
color.__index = color

function color.create(r, g, b, a)
    if type(r) == "string" then
        r, g, b, a = unpack(gfx.hex2color(r))
    end
    local this = {
        r or 1, g or 1, b or 1, a or 1
    }
    return setmetatable(this, color)
end

function color.__tostring(c)
    return string.format("[%0.3f, %0.3f, %0.3f, %0.3f]", unpack(c))
end

function color:__add(c)
    if type(c) == "number" then
        return color.create(
            self[1] + c,
            self[2] + c,
            self[3] + c,
            self[4] + c
        )
    else
        return color.create(
            self[1] + c[1],
            self[2] + c[2],
            self[3] + c[3],
            self[4] + c[4]
        )
    end
end

function color:__sub(c)
    if type(c) == "number" then
        return color.create(
            self[1] - c,
            self[2] - c,
            self[3] - c,
            self[4] - c
        )
    else
        return color.create(
            self[1] - c[1],
            self[2] - c[2],
            self[3] - c[3],
            self[4] - c[4]
        )
    end
end

function color:__mul(s)
    if type(s) == "number" then
        return color.create(
            self[1] * s, self[2] * s, self[3] * s, self[4] * s
        )
    else
        return color.create(
            self[1] * s[1],
            self[2] * s[2],
            self[3] * s[3],
            self[4] * s[4]
        )
    end
end

function color:__div(s)
    if type(s) == "number" then
        return color.create(
            self[1] / s, self[2] / s, self[3] / s, self[4] / s
        )
    else
        return color.create(
            self[1] / s[1],
            self[2] / s[2],
            self[3] / s[3],
            self[4] / s[4]
        )
    end
end


local operators = {}

function operators.dot(c1, ...)
    return c1 * color.create(...)
end

function operators.darken(c1, value)
    return c1 * color.create(value, value, value, 1)
end

function operators.add(c1, ...)
    return c1 + color.create(...)
end

function operators.sub(c1, ...)
    return c1 - color.create(...)
end

local api = {}

local state = list()
local stack = list()

api._stack = list()
api._color = color.create()

function api.push()
    api._stack[#api._stack + 1] = api._color
end

function api.pop()
    if #api._stack <= 0 then return end
    api._color = api._stack:tail()
    api._stack[#api._stack] = nil
    gfx.setColor(unpack(api._color))
end

local function invoke(color, f, ...)
    return f(color, ...) or color
end

function api._reset(state)
    local c = color.create()
    for _, data in ipairs(state) do
        c = invoke(c, unpack(data))
    end
    return c
end

function api.clear()
    api._state = list()
    api._stack = list()
    api._color = color.create()
end

for key, f in pairs(operators) do
    api[key] = function(...)
        api._state = api._state:insert({f, ...})
        api._color = invoke(api._color, f, ...)
        gfx.setColor(unpack(api._color))
    end
end

return api
