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

function color:set(r, g, b, a)
    return color.create(
        r or self[1], g or self[2], b or self[3], a or self[4]
    )
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

function color:darken(value)
    return self * color.create(value, value, value, 1)
end


return color
