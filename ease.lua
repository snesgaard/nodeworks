local ease = require "modules/easing"

function ease.sigmoid(t, b, c, d)
    local low, high = -3, 4
    local function f(x)
        x = (high - low) * x + low
        return 1 / (1 + math.exp(-x))
    end
    local min, max = f(0), f(1)
    local function normalize(s)
        return (s - min) / (max - min)
    end

    t = normalize(f(t / d))

    return c * t + b
end

return ease
