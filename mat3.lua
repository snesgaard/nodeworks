local mat3 = {}
mat3.__index = mat3

function mat3.create(...)
    return setmetatable({...}, mat3)
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
    for c = 1, 3 do
        for r = 1, 3 do
            for i = 1, 3 do
                m3[r + row] = m1[i + r * 3] * m2[c + i * 3]
            end
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

return mat3
