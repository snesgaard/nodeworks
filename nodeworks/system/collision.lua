local nw = require "nodeworks"

local filter_caller = class()

function filter_caller.create(ecs_world)
    return setmetatable({ecs_world=ecs_world}, filter_caller)
end

function filter_caller:set_filter(filter)
    self.filter = filter
end

function filter_caller:__call(...)
    if self.filter then return self.filter(self.ecs_world, ...) end
end

local function do_nothing_filter() return false end

local function add_entity_to_world(entity)
    local hitbox = entity % nw.component.hitbox
    local bump_world = entity % nw.component.bump_world

    if not hitbox or not bump_world then return end

    local pos = entity:ensure(nw.component.position)

    local world_hb = hitbox:move(pos.x, pos.y)

    if not bump_world:hasItem(entity.id) then
        bump_world:add(entity.id, world_hb:unpack())
    else
        bump_world:update(entity.id, world_hb:unpack())
    end
end

local function read_bump_hitbox(ecs_world, id)
    local bump_world = ecs_world:get(nw.component.bump_world, id)
    if not bump_world then return end
    if not bump_world:hasItem(id) then return end
    return spatial(bump_world:getRect(id))
end

local Collision = class()

function Collision.create(world)
    return setmetatable({world = world}, Collision)
end

function Collision:perform_bump_move(bump_world, entity, dx, dy, filter)
    local x, y = bump_world:getRect(entity.id)
    local tx, ty = x + dx, y + dy

    local ecs_world = entity:world()

    local caller = ecs_world:ensure(
        filter_caller.create, "__global__", ecs_world
    )
    caller:set_filter(filter or self.default_filter)
    local ax, ay, col_info = bump_world:move(
        entity.id, tx, ty, caller
    )
    local real_dx, real_dy = ax - x, ay - y

    if self.world then self.world:emit("moved", entity, real_dx, real_dy) end

    if #col_info > 0 then
        for _, ci in ipairs(col_info) do
            ci.ecs_world = entity:world()
            if self.world then self.world:emit("collision", ci) end
        end
    end

    return real_dx, real_dy, col_info
end

function Collision:perform_bump_warp(bump_world, entity, dx, dy)
    return self:perform_bump_move(bump_world, entity, dx, dy, do_nothing_filter)
end

function Collision:move(entity, dx, dy, filter)
    local bump_world = entity % nw.component.bump_world
    local pos = entity:ensure(nw.component.position)

    if not bump_world or not bump_world:hasItem(entity.id) then
        entity:set(nw.component.position, pos + vec2(dx, dy))
        return dx, dy, dict()
    end

    local real_dx, real_dy, col_info = self:perform_bump_move(
        bump_world, entity, dx, dy, filter
    )

    entity:set(nw.component.position, pos + vec2(real_dx, real_dy))

    return real_dx, real_dy, col_info
end

function Collision:move_to(entity, x, y, filter)
    local pos = entity:ensure(nw.component.position)
    local dx, dy = x - pos.x, y - pos.y
    local real_dx, real_dy, col_info = self:move(entity, dx, dy, filter)
    return pos.x + real_dx, pos.y + real_dy, col_info
end

function Collision:move_body(entity, dx, dy, filter)
    local bump_world = entity % nw.component.bump_world
    local hitbox = entity % nw.component.hitbox
    if not hitbox then return 0, 0, {} end

    if not bump_world or not bump_world:hasItem(entity.id) then
        entity:set(
            nw.component.hitbox, hitbox.x + dx, hitbox.y + dy, hitbox.w, hitbox.h
        )
        return dx, dy, dict()
    end

    local real_dx, real_dy, col_info = self:perform_bump_move(
        bump_world, entity, dx, dy, filter
    )

    entity:set(
        nw.component.hitbox,
        hitbox.x + real_dx, hitbox.y + real_dy, hitbox.w, hitbox.h
    )

    return real_dx, real_dy, col_info
end

function Collision:move_body_to(entity, x, y, filter)
    local body = entity % nw.component.hitbox
    if not body then return 0, 0, {} end
    local dx, dy = x - body.x, y - body.y
    local real_dx, real_dy, col_info = self:move_body(
        entity, dx, dy, filter
    )
    return body.x + real_dx, body.y + real_dy, col_info
end

function Collision:warp_to(entity, x, y)
    return self:move_to(entity, x, y, do_nothing_filter)
end

function Collision:warp(entity, dx, dy)
    return self:move(entity, dx, dy, do_nothing_filter)
end

function Collision:class()
    return Collision
end

function Collision.default_filter()
    return "slide"
end

function Collision.on_entity_destroyed(id, values_destroyed)
    local bump_world = values_destroyed[nw.component.bump_world]
    if bump_world and bump_world:hasItem(id) then bump_world:remove(id) end
end

local default_instance = Collision.create()

local assemble = {}

Collision.assemble = assemble

function assemble.set_hitbox(entity, ...)
    entity:set(nw.component.hitbox, ...)
    add_entity_to_world(entity)
end

function assemble.set_bump_world(entity, bump_world)
    local prev_world = entity % nw.component.bump_world

    if prev_world ~= nil and prev_world ~= bump_world then
        prev_world:remove(entity.id)
    end
    entity:set(nw.component.bump_world, bump_world)

    add_entity_to_world(entity)

    local on_entity_destroyed = entity:world().on_entity_destroyed

    if not on_entity_destroyed.collision then
        on_entity_destroyed.collision = Collision.on_entity_destroyed
    end
end

function assemble.init_entity(entity, x, y, hitbox, bump_world)
    entity
        :assemble(assemble.set_hitbox, hitbox:unpack())
        :assemble(assemble.set_bump_world, bump_world)

    default_instance:warp_to(entity, x, y)
end

return function(ctx)
    if not ctx then return default_instance end

    local world = ctx.world or ctx
    world[Collision] = world[Collision] or Collision.create(world)
    return world[Collision]
end

--[[

function ecs_world.on_entity_destroyed.collision(id, values_destroyed)
    local bump_world = values_destroyed[nw.component.bump_world]
    if bump_world and bump_world:has(id) then bump_world:remove(id) end
end

collision(ctx):move_to(entity, 100, 100)
ecs_world:entity():assemble(collision().init_entity, x, y, hitbox, bump_world)

ctx:collision():move_to(entity, 100, 100)
ecs_world:entity():assemble(collision(ctx):init_entity(), x, y, hitbox, bump_world)
]]--
