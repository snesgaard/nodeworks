local function resolve_collision(col)
    if col.item.on_collision then
        col.item.on_collision(col)
    end
end

local function move_filter(item, other)
    -- Ignore terrain
    if other.type ~= "hitbox" then return end
    if other:find("..") == item:find("..") then return end
    return "cross"
end

local hitbox = {}

function hitbox:create(x, y, w, h, world)
    self.world = world or self:find_world()
    self.shape = spatial(x, y, w, h)
    self.transform = transform()
    self.type = "hitbox"
end

function hitbox:find_world()
    local node = self
    while node do
        if node.world then return node.world end
        node = node:find("..")
    end
end

function hitbox:on_adopted()
    self.world = self.world or self:find_world()
end

function hitbox:set_shape(shape)
    self.shape = shape
end

function hitbox:update(dt, args)
    self.world = self.word or self:find_world()
    if not self.world then return end

    local transforms = args.transforms
    local shape = self.shape
    for i = #transforms, 1, -1 do
        local t = transforms[i]
        shape = t:forward(shape)
    end
    if not self.world:hasItem(self) then
        self.world:add(self, shape:unpack())
    else
        self.world:update(self, shape:unpack())
    end

    local _, _, col, len = self.world:check(
        self, shape.x, shape.y, self.move_filter or move_filter
    )
    for i = 1, len do resolve_collision(col[i]) end
end

function hitbox:on_destroyed()
    if self.world:hasItem(self) then
        self.world:remove(self)
    end
end

return hitbox
