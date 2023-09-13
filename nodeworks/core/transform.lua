local transform = class()

function transform.__tostring(t)
    return tostring(dict(t))
end

function transform.constructor(x, y, sx, sy)
    return {x=x or 0, y=y or 0, sx=sx or 1, sy=sy or 1}
end

function transform:invert()
    local sx_inv = 1.0 / self.sx
    local sy_inv = 1.0 / self.sy
    return transform.create(
        -self.x / self.sx, -self.y / self.sy, 1.0 / self.sx, 1.0 / self.sy
    )
end

function transform.__mul(self, other)
    return transform.create(
        self.sx * other.x + self.x,
        self.sy * other.y + self.y,
        self.sx * other.sx,
        self.sy * other.sy
    )
end

function transform:translation() return self.x, self.y end

function transform:scale() return self.sx, self.sy end

function transform:identity() return transform.create(0, 0, 1, 1) end

return transform
