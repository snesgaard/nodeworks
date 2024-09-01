---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.core.spatial"
local spatial = require "nodeworks.core.spatial"
---@module "3rd"
local third = require "3rd"
---@module "misc"
local misc = require "nodeworks.core.misc"
---@module "nodeworks.system.event"
local event = require "nodeworks.system.event"
---@module "event_type"
local event_type = require "nodeworks.event_type"


---@class CollisionInfo
---@field overlaps boolean
---@field ti number
---@field move table
---@field normal table
---@field touch table
---@field itemRect table
---@field otherRect table
---@field type string
---@field item Id
---@field other Id


---@param hitbox Spatial
---@param mirror boolean
---@return number x
---@return number y
local function compute_model_offset(hitbox, mirror)
    local x, y, w, _ = hitbox:unpack()
    if mirror then
        return -x - w, y
    else
        return x, y
    end
end

---@param v number
---@®eturn integer
local function round(v) return math.floor(v + 0.5) end

local private_component = {}

---@param hitbox Spatial
function private_component.bump_membership(hitbox)
    local hitbox = spatial(hitbox.x, hitbox.y, round(hitbox.w), round(hitbox.h))
    return {hitbox = hitbox}
end

function private_component.collision_filter(filter) return filter end

local function oneway_response(world, col, ...)
    local nx, ny = col.normal.x, col.normal.y
    if nx == 0 and ny == -1 then
        col.type = "slide"
        return third.bump.responses.slide(world, col, ...)
    else
        col.type = "cross"
        return third.bump.responses.cross(world, col, ...)
    end
end

function private_component.bump_world() 
    local bump_world = third.bump.newWorld()
    bump_world.rects = misc.create_weak_key_table()
    bump_world:addResponse("oneway", oneway_response)
    return bump_world
end

local collision = {a = nil}

local system_id = "__system_collision__"

function collision.get_bump_world()
    return stack.ensure(private_component.bump_world, system_id)
end

---@param id Id
function collision.unregister(id)
    local bump_world = collision.get_bump_world()
    if bump_world:hasItem(id) then bump_world:remove(id) end

    stack.remove(private_component.bump_membership, id)

    return collision
end

---@param id Id
---@param hitbox Spatial
function collision.register(id, hitbox)
    collision.unregister(id)

    local bump_membership = stack
        .ensure(private_component.bump_membership, id, hitbox)
    
    local bump_world = collision.get_bump_world()
    if bump_world:hasItem(id) then
        misc.errorf("Item %s was already registered somehow", tostring(id))
    end

    local pos = stack.ensure(component.position, id)
    local x, y, w, h = bump_membership.hitbox:unpack()
    bump_world:add(id, x + pos.x, y + pos.y, w, h)

    return collision
end


---@param item Id
---@param other Id
---@return string Collision response e.g. slide
function collision.filter(item, other) return "cross" end


---@param id Id
---@param x number
---@param y number
---@param filter (fun(item: Id, other: Id): string)|nil
---@return number ax Arrival x coordinate
---@return number ay Arrival y coordinate
---@return CollisionInfo[] collision_info List of collisions
function collision.move_to(id, x, y, filter)
    local bump_membership = stack.get(private_component.bump_membership, id)
    if not collision.get_bump_world():hasItem(id) or not bump_membership then
        stack.set(component.position, id, x, y)
        event.emit(event_type.move, id, x, y, {})
        return x, y, {}
    end

    local mirror = stack.get(component.mirror, id) or false

    local dx, dy = compute_model_offset(bump_membership.hitbox, mirror)
    local ax, ay, cols = collision.get_bump_world():move(
        id, x + dx, y + dy, filter or collision.filter
    )

    local ax = ax - dx
    local ay = ay - dy
    stack.set(component.position, id, ax, ay)

    event.emit(event_type.move, id, ax, ay, cols)

    return ax, ay, cols
end

---@param id Id
---@param dx number
---@param dy number
---@param filter (fun(item: Id, other: Id): string)|nil
---@return number dx Relative move x
---@return number dy Relative move y
---@return CollisionInfo[] collision_info List of collisions
function collision.move(id, dx, dy, filter)
    local pos = stack.ensure(component.position, id)
    local x, y = dx + pos.x, dy + pos.y
    local ax, ay, cols = collision.move_to(id, x, y, filter)
    return ax - pos.x, ay - pos.y, cols
end

local function nil_filter() end

---@param id Id
---@param dx number
---@param dy number
function collision.warp(id, dx, dy)
    return collision.move(id, dx, dy, nil_filter)
end

---@param id Id
---@param x number
---@param y number
function collision.warp_to(id, x, y)
    return collision.move_to(id, x, y, nil_filter)
end

---@param id Id
---@return number|nil x
---@return number|nil y
---@return number|nil w
---@return number|nil h
function collision.get_world_hitbox(id)
    local bump_membership = stack.get(private_component.bump_membership, id)
    local bump_world = collision.get_bump_world()
    if not bump_membership or not bump_world:hasItem(id) then return end
    return bump_world:getRect(id)
end

---@param id Id
---@param mirror boolean
---@param filter (fun(item: Id, other: Id): string)|nil
---@return CollisionInfo[]
function collision.flip_to(id, mirror, filter)
    stack.set(component.mirror, id, mirror)
    local pos = stack.ensure(component.position, id)
    local _, _, cols = collision.move_to(id, pos.x, pos.y, filter)
    event.emit(event_type.flip_to, id, mirror)
    return cols
end

---@param id Id
---@param filter (fun(item: Id, other: Id): string)|nil
---@return CollisionInfo[]
function collision.flip(id, filter)
    local mirror = stack.get(component.mirror, id)
    return collision.flip_to(id, not mirror, filter)
end

function collision.draw()
    third.bump_debug.draw_world(collision.get_bump_world())
end

---@param rect Spatial
---@param filter fun(item: Id): boolean
---@return Id[]
function collision.query(rect, filter)
    local bump_world = collision.get_bump_world()
    local ids, _ = bump_world:queryRect(rect.x, rect.y, rect.w, rect.h, filter)
    return ids
end



return collision