local nw = require "nodeworks"
local stack = nw.ecs.stack

local function compute_model_offset(hitbox, mirror)
    local x, y, w, h = hitbox:unpack()
    if mirror then
        return -x - w, y
    else
        return x, y
    end
end

local function round(v) return math.floor(v + 0.5) end

local component = {}

function component.bump_membership(id, hitbox)
    local hitbox = spatial(hitbox.x, hitbox.y, round(hitbox.w), round(hitbox.h))
    return {
        hitbox = hitbox
    }
end

function component.hitbox_type(type) return type end

function component.collision_filter(filter) return filter end

local function oneway_response(world, col, ...)
    local nx, ny = col.normal.x, col.normal.y
    if nx == 0 and ny == -1 then
        col.type = "slide"
        return nw.third.bump.responses.slide(world, col, ...)
    else
        col.type = "cross"
        return nw.third.bump.responses.cross(world, col, ...)
    end
end

local function overlap(ix, iw, ox, ow)
    local ix1 = ix
    local ix2 = ix + iw
    local ox1 = ox
    local ox2 = ox + ow

    return math.min(math.abs(ix1 - ox2), math.abs(ix2 - ox1))
end

local function x_overlap(item_rect, other_rect)
    return overlap(item_rect.x, item_rect.w, other_rect.x, other_rect.w)
end

local function y_overlap(item_rect, other_rect)
    return overlap(item_rect.y, item_rect.h, other_rect.y, other_rect.h)
end

local function better_slide_response(world, col, ...)
    local corner_touch = x_overlap(col.itemRect, col.otherRect) < 1e-10 and y_overlap(col.itemRect, col.otherRect) < 1e-10
    if corner_touch then 
        col.type = "cross"
        return nw.third.bump.responses.cross(world, col, ...)
    else
        col.type = "slide"
        return nw.third.bump.responses.slide(world, col, ...)
    end
end

function component.bump_world() 
    local weak_keys = {__mode = "k"}
    local bump_world = nw.third.bump.newWorld()
    bump_world.rects = setmetatable({}, weak_keys)
    bump_world:addResponse("oneway", oneway_response)
    bump_world:addResponse("better_slide", better_slide_response)
    return bump_world
end

local collision = {}

collision.component = component

function collision.get_bump_world()
    return stack.ensure(component.bump_world, collision)
end

function collision.unregister(id)
    local bump_world = collision.get_bump_world()
    if bump_world:hasItem(id) then bump_world:remove(id) end

    stack.remove(component.bump_membership, id).remove(component.hitbox_type, id)
    return collision
end

function collision.register(id, hitbox, hitbox_type)
    collision.unregister(id)

    local bump_membership = stack
        .set(component.hitbox_type, id, hitbox_type)
        .ensure(component.bump_membership, id, id, hitbox)
    
    local bump_world = collision.get_bump_world()
    if bump_world:hasItem(id) then
        errorf("Item %s was already registered somehow", tostring(id))
    end

    local pos = stack.ensure(nw.component.position, id)
    local x, y, w, h = bump_membership.hitbox:unpack()
    bump_world:add(id, x + pos.x, y + pos.y, w, h)

    return collision
end

function collision.has_item(id)
    local bump_world = collision.get_bump_world()
    return bump_world:hasItem(id)
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
    if not stack.has(component.bump_membership, other) then return end

    if self.filter then return self.filter(item, other) end

    local default_filter = collision.get_default_filter()
    if default_filter then
        return default_filter(item, other)
    else
        return "cross"
    end
end

function collision.move_to(id, x, y, filter)
    local bump_membership = stack.get(component.bump_membership, id)
    if not collision.get_bump_world():hasItem(id) or not bump_membership then
        stack.set(nw.component.position, id, x, y)
        return x, y, list()
    end

    local filter_functor = stack.ensure(CollisionFilter.create, collision)
    filter_functor:set_filter(filter)

    local mirror = stack.get(nw.component.mirror, id)
    local dx, dy = compute_model_offset(bump_membership.hitbox, mirror)
    local ax, ay, cols = collision.get_bump_world():move(
        id, x + dx, y + dy, filter_functor
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
    if not bump_membership or not collision.get_bump_world():hasItem(id) then return end
    return collision.get_bump_world():getRect(id)
end

function collision.get_model_hitbox(id)
    local bump_membership = stack.get(component.bump_membership, id)
    if not bump_membership then return end
    return bump_membership.hitbox:unpack()
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

function collision.query(rect, filter)
    local bump_world = collision.get_bump_world()
    return bump_world:queryRect(rect.x, rect.y, rect.w, rect.h, filter)
end

function collision.from_local(id, rect)
    local mirror = stack.get(nw.component.mirror, id)
    local pos = stack.get(nw.component.position, id) or vec2()
    local x, y = compute_model_offset(rect, mirror)

    return spatial(x + pos.x, y + pos.y, rect.w, rect.h)
end

function collision.query_local(id, rect, filter)
    return collision.query(collision.from_local(id, rect), filter)
end

function collision.spin()
    for id, hb in stack.view_table(nw.component.hitbox) do
        if not collision.has_item(id) then
            collision.register(id, hb)
            local p = stack.get(nw.component.position, id)
            if p then collision.warp_to(id, p.x, p.y) end
            local m = stack.get(nw.component.mirror, id)
            collision.flip_to(id, m, nil_filter)
        end
    end
end

return collision