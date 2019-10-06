local body = {}

local function check_pair(a, b, at, bt)
    return (a == at and b == bt) or (a == bt and b == at)
end

local function default_filter(item, other)
    if check_pair(item.type, other.type, "wall", nil) then
        return false
    end
    if not item.type or not other.type then
        return "slide"
    end
    if item.type == "wall" and other.type == "physical" then
        return "slide"
    end
    if item.type == "physical" and other.type == "wall" then
        return "slide"
    end

    return "cross"
end

local default_gravity = vec2(0, 500)

function body:create(world, x, y, w, h, type)
    self.body = spatial(x, y, w, h)
    self.world = world
    self.speed = vec2(0, 0)
    self.gravity = default_gravity
    self.body.type = type
    world:add(self.body, self.body:unpack())
    --world:update(self.body, x, y)
end

function body:set_gravity(gravity)
    self.gravity = gravity or default_gravity
    return self
end

function body:type(type)
    self.body.type = type
    return self
end

function body:move(x, y, filter)
    local pos = self:pos()
    local x, y, col, len = self.world:move(
        self.body, pos.x + x + self.body.x, pos.y + y + self.body.y,
        filter or default_filter
    )
    pos.x = x - self.body.x
    pos.y = y - self.body.y
    return col, len
end

function body:set_move(x, y, filter)
    local pos = self:pos()
    local x, y, col, len = self.world:move(
        self.body, x + self.body.x, y + self.body.y,
        filter or default_filter
    )
    pos.x = x - self.body.x
    pos.y = y - self.body.y

    return col, len
end

function body:__update(dt)
    if not self.floating then
        self.speed = self.speed + self.gravity * dt
    end
    self.col, self.len = self:move(self.speed.x * dt, self.speed.y * dt)

    if self:on_ground() then
        self.speed.y = math.min(self.speed.y, 0)
    elseif self:on_ceil() then
        self.speed.y = math.max(self.speed.y, 0)
    end
end

function body:on_ground()
    if not self.col then return end
    for _, col in ipairs(self.col) do
        if col.type == "slide" and vec2(0, -1):dot(col.normal) > 0.9 then
            return true
        end
    end
end

function body:on_ceil()
    if not self.col then return end
    for _, col in ipairs(self.col) do
        if col.type == "slide" and vec2(0, -1):dot(col.normal) < -0.9 then
            return true
        end
    end
end

function body:set(x, y)
    self.__transform.pos = vec2(x, y)
    self.world:update(self.body, x, y)
end

function body:pos()
    return self.__transform.pos
end

function body:__draw()
    if __draw_bodies then
        local c = {gfx.getColor()}
        gfx.setColor(0, 1, 0.3)
        gfx.rectangle("line", self.body:unpack())
        gfx.setColor(unpack(c))
    end
end

return body
