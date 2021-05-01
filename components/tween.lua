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

function tween:value()
    local ease = self.__ease or ease.linear
    return ease(self.__time, self.__from, self.__change, self.__duration)
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
