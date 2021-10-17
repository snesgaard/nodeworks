local transform = {}
transform.__index = transform

function transform.__tostring(t)
    return tostring(dict(t))
end

function transform.create(x, y, a, sx, sy)
    local t = {
        position = vec2(x or 0, y or 0),
        angle = a or 0,
        scale = vec2(sx or 1, sy or 1)
    }
    return setmetatable(t, transform)
end

function transform:push()
    gfx.translate(self.position:unpack())
    gfx.rotate(self.angle)
    gfx.scale(self.scale:unpack())
end

function transform:_forward_vector(p)
    local sx, sy = self.scale:unpack()
    local cosa, sina = math.cos(self.angle),math.sin(self.angle)
    -- Forward scale
    local x = p.x * sx
    local y = p.y * sy
    -- Forward rotation
    x = x * cosa - y * sina
    y = x * sina + y * cosa
    -- Forward translation
    x = x + self.position.x
    y = y + self.position.y
    return vec2(x, y)
end

function transform:forward(p)
    if p.w and p.h then
        local c1, c2 = vec2(p.x, p.y), vec2(p.x + p.w, p.y + p.h)
        c1 = self:_forward_vector(c1)
        c2 = self:_forward_vector(c2)
        return spatial(c1.x, c1.y, c2.x - c1.x, c2.y - c1.y)
            :sanitize()
    else
        return self:_forward_vector(p)
    end
end

function transform:_inverse_vector(p)
    local sx, sy = self.scale:unpack()
    local cosa, sina = math.cos(self.angle), math.sin(self.angle)
    -- Inverse translation
    local x = p.x - self.position.x
    local y = p.y - self.position.y
    -- Inverse rotation
    x = x * cosa + y * sina
    y = -x * sina + y * cosa
    -- Inverse scale
    x = x / sx
    y = y / sy
    return vec2(x, y)
end

function transform:inverse(p)
    if p.w and p.h then
        local c1, c2 = vec2(p.x, p.y), vec2(p.x + p.w, p.y + p.h)
        c1 = self:_inverse_vector(c1)
        c2 = self:_inverse_vector(c2)
        return spatial(c1.x, c1.y, c2.x - c1.x, c2.y - c1.y)
            :sanitize()
    else
        self:_inverse_vector(p)
    end
end

function transform:forward_matrix()
    local sx, sy = self.scale:unpack()
    local cosa, sina = math.cos(self.angle), math.sin(self.angle)
    local dx, dy = self.position:unpack()
    return mat3.create(
        sx * cosa, -sy * sina, dx,
        sx * sina, sy * cosa, dy,
        0, 0, 1
    )
end

function transform:inverse_matrix()
    local sx, sy = self.scale:unpack()
    local cosa, sina = math.cos(self.angle), math.sin(self.angle)
    local dx, dy = self.position:unpack()

    local tx = (-dx * cosa + dy * sina) / sx
    local ty = (dx * sina - dy * cosa) / sy
    return mat3.create(
        cosa / sx, sina / sx, tx,
        -sina / sy, cosa / sy, ty,
        0, 0, 1
    )
end

return transform
