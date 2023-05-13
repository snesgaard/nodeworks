local nw = require "nodeworks"
local stack = nw.ecs.stack

local function compute_model_offset(hitbox, mirror)
    local x, y, h, w = hitbox:unpack()
    if mirror then
        return -x - w, y
    else
        return x, y
    end
end

local component = {}

function component.bump_membership(id, hitbox)
    return {
        id = id,
        hitbox = hitbox
    }
end

function component.hitbox_type(type) return type end

function component.collision_filter(filter) return filter end

function component.bump_world() 
    local weak_keys = {__mode = "k"}
    local bump_world = nw.third.bump.newWorld()
    bump_world.rects = setmetatable({}, weak_keys)
    return bump_world
end

local collision = {}

function collision.get_bump_world()
    return stack.ensure(component.bump_world, collision)
end

function collision.unregister(id)
    local bump_membership = stack.get(component.bump_membership, id)
    if not bump_membership then return end

    local bump_world = collision.get_bump_world()
    if bump_world:hasItem(bump_membership) then bump_world:remove(bump_membership) end

    stack.remove(component.bump_membership, id).remove(component.hitbox_type, id)
    return collision
end

function collision.register(id, hitbox, hitbox_type)
    collision.unregister(id)

    local bump_membership = stack
        .set(component.hitbox_type, id, hitbox_type)
        .ensure(component.bump_membership, id, id, hitbox)
    
    local bump_world = collision.get_bump_world()
    if bump_world:hasItem(bump_membership) then
        errorf("Item %s was already registered somehow", tostring(id))
    end

    local pos = stack.ensure(nw.component.position, id)
    local x, y, w, h = bump_membership.hitbox:unpack()
    bump_world:add(bump_membership, x + pos.x, y + pos.y, w, h)

    return collision
end

function collision.set_default_filter(filter)
    stack.set(component.collision_filter, collision, filter)
    return collision
end

function collision.get_default_filter()
    return stack.get(component.collision_filter, collision)
end

local CollisionFilter = class()

function CollisionFilter:set_filter(filter) self.filter = filter end

function CollisionFilter:__call(item, other)
    -- If no bump membership is present, the other cannot collide
    if not stack.has(component.bump_membership, other.id) then return end

    if self.filter then return self.filter(item.id, other.id) end

    local default_filter = collision.get_default_filter()
    if default_filter then
        return default_filter(item.id, other.id)
    else
        return "cross"
    end
end

function collision.move_to(id, x, y, filter)
    local bump_membership = stack.get(component.bump_membership, id)
    if not bump_membership then
        stack.set(nw.component.position, x, y)
        return x, y, list()
    end

    local filter_functor = stack.ensure(CollisionFilter.create, collision)
    filter_functor:set_filter(filter)

    local mirror = stack.get(nw.component.mirror, id)
    local dx, dy = compute_model_offset(bump_membership.hitbox, mirror)
    local ax, ay, cols = collision.get_bump_world():move(
        bump_membership, x + dx, y + dy, filter_functor
    )

    local ax = ax - dx
    local ay = ay - dy
    stack.set(nw.component.position, id, ax, ay)

    nw.system.event.emit("move", ax, ay, cols)

    return ax, ay, cols
end

function collision.move(id, dx, dy, filter)
    local pos = stack.ensure(nw.component.position, id)
    local x, y = dx + pos.x, dy + pos.y
    local ax, ay, cols = collision.move_to(id, x, y, filter)
    return ax - pos.x, ay - pos.y, cols
end

local function nil_filter() end

function collision.warp_to(id, x, y)
    collision.move_to(id, x, y, nil_filter)
    return collision
end

function collision.warp(id, dx, dy)
    collision.move(id, dx, dy, nil_filter)
    return collision
end

function collision.get_world_hitbox(id)
    local bump_membership = stack.get(component.bump_membership, id)
    if not bump_membership then return end
    return collision.get_bump_world():getRect(bump_membership)
end

function collision.flip_to(id, mirror, filter)
    stack.set(nw.component.mirror, id, mirror)
    local pos = stack.ensure(nw.component.position, id)
    local _, _, cols = collision.move_to(id, pos.x, pos.y, filter)
    return cols
end

function collision.flip(id, filter)
    local mirror = stack.get(nw.component.mirror, id)
    return collision.flip_to(id, not mirror, filter)
end

function collision.draw()
    bump_debug.draw_world(collision.get_bump_world())
end

return collision