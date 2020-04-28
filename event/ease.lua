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

-- This assumes vec2 values
function ease.jump(subease)
    subease = subease or ease.linear
    return function(t, b, c, d)
        local s = math.min(1, subease(t, 0, 1, d))
        local c0 = b
        local c3 = c + b
        local d = c3 - c0
        local dist = d:length() * 0.15

        local c1 = c0 - vec2(0, dist) + d * 0.2
        local c2 = c3 - vec2(0, dist) - d * 0.2
        local curve = love.math.newBezierCurve(
            c0.x, c0.y,
            c1.x, c1.y,
            c2.x, c2.y,
            c3.x, c3.y
        )
        return vec2(curve:evaluate(s))
    end
end

function ease.cubicbezier(x1, y1, x2, y2)
  local curve = love.math.newBezierCurve(0, 0, x1, y1, x2, y2, 1, 1)
  return function (t, b, c, d) return c * curve:evaluate(t/d) + b end
end
