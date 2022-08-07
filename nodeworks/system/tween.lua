local nw = require "nodeworks"

--[[
tween(ctx):move_to(nw.component.position, entity, value, duration)

tween(ctx, nw.component.position):move_to(entity, value, duration)

tween(ctx)
    :as(nw.component.position)
    :move_to(entity, value, duration)
]]--


local TweenEntity = class()

function TweenEntity.create(master, entity)
    return setmetatable({master=master, entity=entity}, TweenEntity)
end

local mapped_apis = {
    "ensure", "move_to", "warp_to", "assign",
    "set", "done"
}

for _, name in ipairs(mapped_apis) do
    TweenEntity[name] = function(self, ...)
        local f = self.master[name]
        if not f then return self end
        f(self.master, self.entity, ...)
        return self
    end
end

local return_apis = {"get", "has"}

for _, name in ipairs(return_apis) do
    TweenEntity[name] = function(self, ...)
        local f = self.master[name]
        if not f then return self end
        return f(self.master, self.entity, ...)
    end
end

function TweenEntity:update()
    self.master:update()
    return self
end

local weak_table = {__mode = "k"}

local TweenComponent = class()

function TweenComponent.compute_square_distance(a, b)
    if type(a) == "table" and type(b) == "table" then
        local sum = 0
        for key, value in pairs(a) do
            local d = value - b[key]
            sum = sum + d * d
        end
        return sum
    elseif type(a) == "number" and type(b) == "number" then
        local d = a - b
        return d * d
    else
        errorf("Unsupported types %s and %s", type(a), type(b))
    end
end

function TweenComponent.create(component)
    local this = setmetatable(
        {
            entities=setmetatable({}, weak_table),
            entity_assign=setmetatable({}, weak_table),
            default_duration = 0.1,
            component=component
        },
        TweenComponent
    )

    function this.signature(...) return nw.component.tween(...) end

    return this
end

function TweenComponent:update(dt)
    local dt = dt or 0
    for entity, _ in pairs(self.entities) do
        local tween = entity:get(self.signature)
        if tween then
            tween:update(dt)
            local assign = self.entity_assign[entity]
            local value = tween:value()
            if assign then assign(entity, value) end
        end
    end

    return self
end

function TweenComponent:get(entity)
    local t = entity:get(self.signature)
    if t then return t:value() end
end

function TweenComponent:has(entity) return entity:has(self.signature) end

function TweenComponent:ensure(entity, ...)
    if self:has(entity) then return self:get(entity) end
    return self:move_to(entity, ...)
end

function TweenComponent:move_to(entity, value, duration, ease)
    local tween = entity:get(self.signature)
    if not tween then return self:warp_to(entity, value) end

    local threshold = 0.1
    local to = tween:to()
    local sq_dist = TweenComponent.compute_square_distance(to, value)
    if sq_dist < threshold * threshold then return self end

    return self:set(
        entity, tween:value(), value,
        duration or self.default_duration, ease
    )
end

function TweenComponent:warp_to(entity, value)
    return self:set(entity, value, value, 0.0001)
end

function TweenComponent:set(entity, from, to, duration, ease)
    self.entities[entity] = to
    self.entity_assign[entity] = nil
    entity:set(self.signature, from, to, duration, ease)
    return self
end

function TweenComponent:assign(entity, assign)
    self.entity_assign[entity] = assign
    local v = self:get(entity)
    if v then assign(entity, v) end
    return self
end

function TweenComponent:done(entity)
    local t = entity:get(self.signature)
    if not t then return true end
    return t:is_done()
end

function TweenComponent:entity(entity)
    return TweenEntity.create(self, entity)
end

local function system(ctx, tween_master)
    local update = ctx:listen("update"):collect()
    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            tween_master:update(dt)
        end
        ctx:yield()
    end
end

local TweenMaster = class()

function TweenMaster.create(world)
    local this = setmetatable(
        {tweens={}, world=world},
        TweenMaster
    )
    this.ctx = world:ensure(system, this)
    return this
end

function TweenMaster:as(component)
    if not self.tweens[component] then
        self.tweens[component] = TweenComponent.create(component)
    end

    return self.tweens[component]
end

function TweenMaster:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end
    return self
end

return function(ctx)
    if not ctx then
        errorf("Context or world must be given")
    end

    local world = ctx.world or ctx
    world[TweenMaster] = world[TweenMaster] or TweenMaster.create(world)
    return world[TweenMaster]
end
