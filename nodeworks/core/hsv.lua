local hsv = {}
hsv.__index = hsv

function hsv.create(h, s, v)
    return setmetatable({h=h, v=v, s=s}, hsv)
end

function hsv:__tostring()
    return string.format("HSV[%.2f, %.2f, %.2f]", self.h, self.s, self.v)
end

function hsv:print()
    print(self)
    return self
end

function hsv.from_rgb(r, g, b)
    local h, s, v
    local min = math.min(r, g, b)
    local max  = math.max(r, g, b)
    local delta = max - min
    -- value
    v = max
    -- saturation
    if delta ~= 0 then -- we know max won't be zero, as min can't be less than zero and the difference is not 0
        s = delta / max
    else
        h = -1
        s = 0
        return hsv.create(h, s, v)
    end
    -- hue
    if r == max then -- yellow <-> magenta
        h = (g - b) / delta
    elseif g == max then -- cyan <-> yellow
        h = 2 + (b - r) / delta
    else -- magenta <-> cyan
        h = 4 + (r - g) / delta
    end
    h = h * 60 -- 60 degrees
    if h < 0 then
        h = h + 360
    end
    return hsv.create(h, s, v)
end

function hsv:to_rgb()
    local h, s, v = self.h, self.s, self.v
    local r, g, b
    if s == 0 then -- monochromatic
        return {v, v, v}
    end

    h = h / 60 -- sector of wheel
    local i = math.floor(h)
    local f = h - i -- factorial part of h
    local p = v * (1 - s)
    local q = v * (1 - s * f)
    local t = v * (1 - s * (1 - f))

    if i == 0 then
        r = v
        g = t
        b = p
    elseif i == 1 then
        r = q
        g = v
        b = p
    elseif i == 2 then
        r = p
        g = v
        b = t
    elseif i == 3 then
        r = p
        g = q
        b = v
    elseif i == 4 then
        r = t
        g = p
        b = v
    else
        r = v
        g = p
        b = q
    end

    return {r, g, b}
end

function hsv:hue_shift(target_hue, power)
    local power = power or 1
    local hue_diff = math.fmod(target_hue - self.h + 180, 360) - 180;
    local real_diff = hue_diff < -180  and (hue_diff + 360) or hue_diff
    self.h = self.h + real_diff * power
    while self.h < 0 do
        self.h = self.h + 360
    end
    return self
end

function hsv:change_hue(dh)
    self.h = self.h + dh
    while self.h < 0 do
        self.h = self.h + 360
    end

    while self.h > 360 do
        self.h = self.h - 360
    end

    return self
end

function hsv:change_saturation(ds)
    self.s = math.clamp(self.s + ds, 0, 1)
    return self
end

function hsv:change_value(dv)
    self.v = math.clamp(self.v + dv, 0, 1)
    return self
end

return hsv
