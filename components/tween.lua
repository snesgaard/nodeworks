local tween = {}
tween.__index = tween

function tween:is_done()
    return self.__time >= self.__duration
end

function tween:update(dt)
    self.__delay = math.max(0, self.__delay - dt)

    if self.__delay > 0 then return self:value() end

    self.__time = math.min(self.__duration, self.__time + dt)

    return self:value()
end

function tween:value(time)
    local ease = self.__ease or ease.linear
    time = time or self.__time
    return ease(time, self.__from, self.__change, self.__duration)
end

function tween:derivative(time, dt)
    time = time or self.time
    dt = dt or 0.016
    local v2 = self:value(time)
    local v1 = self:value(time - dt)
    return (v2 - v1) / dt
end

function tween:ease(ease)
    self.__ease = ease
    return self
end

function tween:delay(delay)
    self.__delay = delay
    return self
end

function tween:time(time)
    self.__time = time
end

function tween:complete()
    self.__time = self.__duration
    return self
end

function tween:get_duration() return self.__duration end

return function(from, to, duration)
    return setmetatable(
        {
            __from = from,
            __to = to,
            __change = to - from,
            __duration = duration,
            __time = 0,
            __delay = 0,
        },
        tween
    )

end
