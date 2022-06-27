local tween_master = {}
tween_master.__index = tween_master

local function compute_square_distance(a, b)
    if type(a) == "table" and type(b) == "table" then
        local sum = 0
        for key, value in pairs(a) do
            local d = value - b[key]
            sum = sum + d * d
        end
        return sum
    elseif type(a) == "number" and type(b) == "number" then
        local d = a - b
        return d * d
    else
        errorf("Unsupported types %s and %s", type(a), type(b))
    end
end

function tween_master.create()
    return setmetatable(
        {
            tweens = {},
            threshold = 1,
            default_duration = 0.1
        },
        tween_master
    )
end

function tween_master:update(dt)
    for _, t in pairs(self.tweens) do t:update(dt) end
end

function tween_master:get(id)
    local t = self.tweens[id]
    if not t then return end
    return t:value()
end

function tween_master:has(id)
    return self.tweens[id]
end

function tween_master:ensure(id, ...)
    if self:has(id) then return self:get(id) end
    return self:move_to(id, ...)
end

function tween_master:move_to(id, value, duration, ease)
    if not self:has(id) then return self:warp_to(id, value) end
    local t = self.tweens[id]
    local to = t:to()
    local sq_dist = compute_square_distance(to, value)
    if sq_dist < self.threshold * self.threshold then return t:value() end

    self:set(id, t:value(), value, duration or self.default_duration, ease)
    return self:get(id)
end

function tween_master:warp_to(id, value)
    self:set(id, value, value, 1)
    return self:get(id)
end

function tween_master:set(id, from, to, duration, ease)
    local nw = require "nodeworks"
    self.tweens[id] = nw.component.tween(from, to, duration, ease)
    return self
end

function tween_master:done(id)
    local t = self.tweens[id]
    if not t then return true end
    return t:is_done()
end

return tween_master
