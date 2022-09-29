local nw = require "nodeworks"

--[[
tween(ctx):move_to(nw.component.position, entity, value, duration)

tween(ctx, nw.component.position):move_to(entity, value, duration)

tween(ctx)
    :as(nw.component.position)
    :move_to(entity, value, duration)

tween(ctx)
    :as(nw.component.position)
    :entity(hook)
    :move_to(value, duration)
    :assign(function(motion)
        collision(ctx):move(hook, motion.x, motion.y)
    end)

tween(ctx):update(dt, ecs_world)
]]--


local TweenEntity = class()

function TweenEntity.create(master, entity)
    entity:remove(master.signature_assign)
    return setmetatable({master=master, entity=entity}, TweenEntity)
end

function TweenEntity:assign(func)
    self.entity:set(self.master.signature_assign, func)
    self.master:do_assign(self.entity)
    return self
end

local function assign_to_component(entity, value, component)
    entity:set(component, value)
end

function TweenEntity:assign_to_component()
    return self:assign(assign_to_component)
end

function TweenEntity:destroy_on_completion()
    self.entity:set(nw.component.release_on_complete, true)
    return self
end

local mapped_apis = {
    "ensure", "ensure_from_component", "move_to", "warp_to",
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
            default_duration = 0.1,
            component=component
        },
        TweenComponent
    )

    function this.signature(...) return nw.component.tween(...) end
    function this.signature_assign(func) return func end

    return this
end

function TweenComponent:update(dt, ...)
    local dt = dt or 0

    for _, ecs_world in ipairs{...} do
        for id, tween in pairs(ecs_world:table(self.signature)) do
            local entity = ecs_world:entity(id)
            tween:update(dt)
            if self.on_tween_updated then
                self.on_tween_updated(entity, tween:value(), self.component)
            end
            self:do_assign(entity, tween)
        end

        for id, tween in pairs(ecs_world:table(self.signature)) do
            local release_on_complete = ecs_world:get(
                nw.component.release_on_complete, id
            )
            if release_on_complete and tween:is_done() then
                ecs_world:destroy(id)
            end
        end
    end

    return self
end

function TweenComponent:do_assign(entity, tween)
    local tween = tween or entity:get(self.signature)
    local assign = entity:get(self.signature_assign)
    if not assign or not tween then return end
    assign(entity, tween:value(), self.component)
end

function TweenComponent:get(entity)
    local t = entity:get(self.signature)
    if t then return t:value() end
end

function TweenComponent:has(entity) return entity:has(self.signature) end

function TweenComponent:ensure(entity, ...)
    if self:has(entity) then return self:get(entity) end
    return self:warp_to(entity, ...)
end

function TweenComponent:ensure_from_component(entity)
    if self:has(entity) then return self:get(entity) end
    return self:warp_to(entity, entity:ensure(self.component))
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
    entity:set(self.signature, from, to, duration, ease)
    self:do_assign(entity)
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

local TweenMaster = class()

function TweenMaster.create()
    local this = setmetatable({tweens={}}, TweenMaster)
    return this
end

function TweenMaster:as(component)
    if not self.tweens[component] then
        self.tweens[component] = TweenComponent.create(component)
    end

    return self.tweens[component]
end

function TweenMaster:update(dt, ...)
    for _, tween in pairs(self.tweens) do tween:update(dt, ...) end
    return self
end

local WorldTweenMaster = inherit(TweenMaster)

function WorldTweenMaster.create(world)
    local this = TweenMaster.create()
    local this = setmetatable(this, WorldTweenMaster)
    this.world = world
    return this
end

function WorldTweenMaster:as(component)
    local component_tween = TweenMaster.as(self, component)

    return component_tween
end

function WorldTweenMaster.from_ctx(ctx)
    if not ctx then
        errorf("Context or world must be given")
    end

    local world = ctx.world or ctx
    world[WorldTweenMaster] = world[WorldTweenMaster] or WorldTweenMaster.create(world)
    return world[WorldTweenMaster]
end

function WorldTweenMaster.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function WorldTweenMaster.handle_observables(ctx, obs, ...)
    for _, dt in ipairs(obs:pop()) do
        WorldTweenMaster.from_ctx(ctx):update(dt, ...)
    end
end

return WorldTweenMaster.from_ctx
