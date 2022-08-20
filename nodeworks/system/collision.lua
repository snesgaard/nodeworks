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

local function forward_transform(hitbox, position, mirror)
    local hitbox = hitbox or spatial()
    local position = position or vec2()

    if mirror then hitbox = hitbox:hmirror() end

    return hitbox:move(position.x, position.y)
end

local function forward_transform_from_entity(entity)
    return forward_transform(
        entity % nw.component.hitbox,
        entity % nw.component.position,
        entity % nw.component.mirror
    )
end

local function get_state(entity)
    return entity % nw.component.bump_world, entity:ensure(nw.component.hitbox),
        entity:ensure(nw.component.position), entity:ensure(nw.component.mirror)
end

local function add_entity_to_world(entity)
    local hitbox = entity % nw.component.hitbox
    local bump_world = entity % nw.component.bump_world

    if not hitbox or not bump_world then return end

    local world_hb = forward_transform_from_entity(entity)

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

function Collision.create()
    return setmetatable({}, Collision)
end

function Collision:on_moved(entity, real_dx, real_dy, collision_infos)

end

function Collision:on_collision(entity, collision_infos)

end

function Collision:on_mirror(entity, mirror, collision_infos)

end

function Collision:move_to_state(entity, bump_world, hitbox, pos, mirror, filter)
    local next_hitbox = forward_transform(hitbox, pos, mirror)

    local x, y = bump_world:getRect(entity.id)

    local ecs_world = entity:world()
    local caller = ecs_world:ensure(
        filter_caller.create, "__global__", ecs_world
    )
    caller:set_filter(filter or self.default_filter)

    local ax, ay, col_info = bump_world:move(
        entity.id, next_hitbox.x, next_hitbox.y, caller
    )


    self:update_position(entity)

    if #col_info > 0 then self:on_collision(entity, col_info) end

    local dx, dy = ax - x, ay - y

    return dx, dy, col_info
end

function Collision:update_position(entity)
    local bump_world, hb, pos, mirror = get_state(entity)
    local world_rect_expected = forward_transform(hb, pos, mirror)
    local x, y = bump_world:getRect(entity.id)

    local dx, dy = world_rect_expected.x - x, world_rect_expected.y - y

    entity:set(nw.component.position, pos.x - dx, pos.y - dy)
    self:on_moved(entity, dx, dy, col_info)
end

function Collision:move_to(entity, x, y, filter)
    local bump_world, hb, pos, mirror = get_state(entity)
    local pos_next = vec2(x, y)

    local dx, dy, col_info = self:move_to_state(
        entity, bump_world, hb, pos_next, mirror, filter
    )

    return pos.x + dx, pos.y + dy, col_info
end

function Collision:move_hitbox_to(entity, x, y, filter)
    local bump_world, hb, pos, mirror = get_state(entity)
    local hb_next = spatial(x, y, hb.w, hb.h)

    entity:set(nw.component.hitbox, hb_next:unpack())
    local dx, dy, col_info = self:move_to_state(
        entity, bump_world, hb_next, pos, mirror, filter
    )


    return col_info
end

function Collision:mirror_to(entity, mirror_next, filter)
    local bump_world, hb, pos, mirror = get_state(entity)

    if mirror == mirror_next then return {} end

    entity:set(nw.component.mirror, mirror_next)
    local dx, dy, col_info = self:move_to_state(
        entity, bump_world, hb, pos, mirror_next, filter
    )


    self:on_mirror(entity, mirror_next)

    return col_info
end

function Collision:move(entity, dx, dy, filter)
    local pos = entity:ensure(nw.component.position)

    local ax, ay, col_info = self:move_to(
        entity, pos.x + dx, pos.y + dy, filter
    )

    return ax - pos.x, ay - pos.y, col_info
end

function Collision:warp_to(entity, x, y)
    return self:move_to(entity, x, y, do_nothing_filter)
end

function Collision:warp(entity, dx, dy)
    return self:move(entity, dx, dy, do_nothing_filter)
end

function Collision:move_hitbox(entity, dx, dy, filter)
    local hb = entity:ensure(nw.component.hitbox)

    return self:move_hitbox_to(entity, hb.x + dx, hb.y + dy, filter)
end

function Collision:mirror(entity, filter)
    local mirror = entity:get(nw.component.mirror)
    return self:mirror_to(entity, not mirror, filter)
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

local WorldCollision = inherit(Collision)

function WorldCollision.create(world)
    local this = Collision.create()
    this.world = world
    return setmetatable(this, WorldCollision)
end

function WorldCollision:on_moved(entity, dx, dy)
    self.world:emit("moved", entity, dx, dy)
end

function WorldCollision:on_collision(entity, collision_infos)
    for _, col_info in ipairs(collision_infos) do
        col_info.ecs_world = entity:world()
        self.world:emit("collision", col_info)
    end
end

function WorldCollision:on_mirror(entity, mirror)
    self.world:emit("mirror", entity, mirror)
end

return function(ctx)
    if not ctx then return default_instance end

    local world = ctx.world or ctx
    world[Collision] = world[Collision] or WorldCollision.create(world)
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
