local function is_overlapping(world, token, x, y, w, h)
    local _, _, _, len = world:check(token, x, y, w, h)
    return len > 0
end

local function move_filter(item, other)
    -- Assume geometry
    if not other.type then
        local prop = other.properties or {}
        if prop.oneway then
            return "oneway_slide"
        else
            return "slide"
        end
    end
end

local function move_filter_no_oneway(item, other)
    if not other.type then
        local prop = other.properties or {}
        if not prop.oneway then
            return "slide"
        end
    end
end

local body = {}

body.default_gravity = vec2(0, 300)

function body.jump_curve(height, time)
    local acceleration = 2 * height / (time * time)
    local velocity = -2 * height  / time
    return acceleration, velocity
end

function body:create(world, x, y, w, h)
    self.world = world
    if x then
        self.shape = spatial(x, y, w, h)
    end
    self.transform = transform()
    self.type = "body"
    self.gravity = body.default_gravity
    self.velocity = vec2(0, 0)
end

function body:set_gravity(gravity)
    self.gravity = gravity or self.default_gravity
end

function body:is_valid()
    if not self.shape then return false end
    if not self.world:hasItem(self) then return false end
    return true
end

function body:can_warp(x, y)
    if not self:is_valid() then return false end

    local p = self.transform.position
    self.transform.position = vec2(x, y)
    local world_body = self.transform:forward(self.shape)
    self.transform.position = p
    local _, len = self.world:queryRect(
        world_body.x, world_body.y, world_body.w, world_body.h,
        function(item)
            return item ~= self
        end
    )
    return len == 0
end

function body:warp(x, y)
    if not self:is_valid() then return self end

    self.transform.position = vec2(x, y)
    local world_body = self.transform:forward(self.shape)
    self.world:update(self, world_body:unpack())
    return self
end

function body:can_reshape(x, y, w, h)
    local new_shape = spatial(x, y, w, h)
    local world_body = self.transform:forward(new_shape)
    local _, len = self.world:queryRect(
        world_body.x, world_body.y, world_body.w, world_body.h,
        function(item)
            return item ~= self
        end
    )
    return len == 0
end

function body:update(dt, args)
    if not self.shape then return end

    self.velocity = self.velocity + self.gravity * dt
    self.transform.position = self.transform.position + self.velocity * dt

    local new = self.transform:forward(self.shape)
    if not self.world:hasItem(self) then
        self.world:add(self, new:unpack())
        return
    end

    local old = spatial(self.world:getRect(self))
    local is_different = old.w ~= new.w or old.h ~= new.h
    if is_different and self.paranoid then
        error("A change in size, did you set scale in runtime?")
    elseif is_different then
        --print(new, old)
        --self.world:update(self, new:unpack())
    end

    local col, len = self:move()

    local function valid_type_vertical(col)
        if col.type == "oneway_slide" then
            return col.didTouch
        else
            return true
        end
    end

    local function valid_type_horizontal(col)
        return col.type ~= "oneway_slide"
    end


    self.on_ground = false
    for i = 1, len do
        local c = col[i]
        event(self, "collision")
        if valid_type_vertical(c) and c.normal.y < -0.9 then
            self.velocity.y = math.min(0, self.velocity.y)
            self.ground = love.timer.getTime()
            self.on_ground = true
            event(self, "ground", self.ground)
            if self.on_ground_collision then
                self:on_ground_collision()
            end
        elseif valid_type_vertical(c) and c.normal.y > 0.9 then
            self.velocity.y = math.max(0, self.velocity.y)
        elseif valid_type_horizontal(c) then
            event(self, "side", c.normal.x, c.normal.y)
        end
    end
end

function body:reshape(...)
    self.shape = spatial(...)
end

function body:get_shape()
    return spatial(self.world:getRect(self))
end

function body:move(x, y, is_relative, ignore_oneway)
    if is_relative then
        self.transform.position = self.transform.position + vec2(x, y)
    elseif x then
        self.transform.position = vec2(x, y)
    end

    if not self:is_valid() then return {}, 0 end

    local x_ac, y_ac = self.transform:forward(self.shape):unpack()
    local filter = ignore_oneway and move_filter_no_oneway or move_filter
    local ax, ay, col, len = self.world:move(self, x_ac, y_ac, filter)
    self.transform.position = self:resolve_translation()
    return col, len
end

function body:relative_move(x, y, ignore_oneway)
    return self:move(x, y, true, ignore_oneway)
end

function body:resolve_translation()
    local body_world = spatial(self.world:getRect(self))

    local scale_body = self.shape
        :scale(self.transform.scale:unpack())
        :sanitize()

    local tx = body_world.x - scale_body.x
    local ty = body_world.y - scale_body.y
    return vec2(tx, ty)
end

function body:on_destroyed()
    if self.world:hasItem(self) then
        self.world:remove(self)
    end
end

return body
