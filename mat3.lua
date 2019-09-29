local mat3 = {}
mat3.__index = mat3

function mat3.create(...)
    return setmetatable({...}, mat3)
end

function mat3:__tostring()
    return string.format(
        "%f %f %f\n%f %f %f\n%f %f %f\n",
        unpack(self)
    )
end


function mat3.__add(m1, m2)
    local m3 = mat3.create()
    for i = 1, 9 do
        m3[i] = m1[i] + m2[i]
    end
    return m3
end

function mat3.__sub(m1, m2)
    local m3 = mat3.create()
    for i = 1, 9 do
        m3[i] = m1[i] - m2[i]
    end
    return m3
end

function mat3.__mul(m1, m2)
    local m3 = mat3.create()
    for r = 1, 3 do
        local row = (r - 1) * 3
        for c = 1, 3 do
            local s = 0
            for i = 1, 3 do
                 s = s + m1[i + row] * m2[c + (i - 1) * 3]
            end
            m3[c + row] = s
        end
    end
    return m3
end

function mat3:transform(v)
    local vx, vy = v:unpack()
    local x = self[1] * vx + self[2] * vy + self[3]
    local y = self[4] * vx + self[5] * vy + self[6]
    local z = self[7] * vx + self[8] * vy + self[9]
    return vec2(x / z, y / z)
end

function mat3.rotate(angle)
    local cosa, sina = math.cos(angle), math.sin(angle)
    return mat3.create(
        cosa, -sina, 0,
        sina, cosa, 0,
        0, 0, 1
    )
end

function mat3.translate(dx, dy)
    return mat3.create(
        1, 0, dx,
        0, 1, dy,
        0, 0, 1
    )
end

function mat3.scale(sx, sy)
    return mat3.create(
        sx, 0, 0,
        0, sy, 0,
        0, 0, 1
    )
end

function mat3.identity()
    return mat3.create(
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    )
end

return mat3
