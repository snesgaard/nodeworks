local nw = require "nodeworks"

local system = nw.ecs.system.from_function(
    function(entity)
        return {
            hitboxes = entity:has(
                nw.component.bump_world, nw.component.hitbox, nw.component.position
            ),
            collections = entity:has(
                nw.component.bump_world, nw.component.hitbox_collection,
                nw.component.position
            )
        }
    end
)

local function move_filter(item, other, ...)
    local f = item[nw.component.move_filter] or function() end
    local t = f(item, other)
    if t then return t end


    if not item[nw.component.body] or not other[nw.component.body] then return "cross" end
    if item[nw.component.oneway] then return "cross" end

    if other[nw.component.oneway] then
        local item_hb = system.get_world_hitbox(item)
        local other_hb = system.get_world_hitbox(other)
        if item_hb.y + item_hb.h - other_hb.y > 0 then return "cross" end
    end

    return "slide"
end

local function check_filter() return "cross" end

system.default_move_filter = move_filter

function system.bump_world()
    return nw.third.bump.newWorld()
end

function system.get_world_hitbox(entity)
    return system.transform(entity[nw.component.hitbox], entity)
end

function system.transform(hitbox, parent_entity)
    return hitbox:move(parent_entity[nw.component.position]:unpack())
end

function system.create_hitbox(entity, world, parent_entity)
    parent_entity = parent_entity or entity

    local bump_world = parent_entity[nw.component.bump_world]
    local hitbox = entity[nw.component.hitbox]

    if not hitbox or bump_world:hasItem(entity) then return end

    local world_hitbox = system.transform(hitbox, parent_entity)

    bump_world:add(entity, world_hitbox:unpack())

    local _, _, cols = bump_world:move(entity, world_hitbox.x, world_hitbox.y, check_filter)
    -- Check collision here
    if #cols > 0 then
        world("on_collision", cols)
    end
end

function system.create_collection(entity, world)
    local colletion = entity[nw.component.hitbox_collection]
    if not colletion then return end
    for _, hitbox in ipairs(colletion) do
        hitbox:add(nw.component.parent, entity)
        system.create_hitbox(hitbox, world, entity)
    end
end

function system:on_entity_added(entity, pool)
    if pool == self.hitboxes then
        system.create_hitbox(entity, self.world)
    elseif pool == self.collections then
        system.create_collection(entity, self.world)
    end
end

function system.update_hitbox(entity, world, parent_entity)
    parent_entity = parent_entity or entity
    local bump_world = parent_entity[nw.component.bump_world]
    local world_hitbox = system.transform(hitbox, parent_entity)
    bump_world:update(entity, world_hitbox:unpack())

    -- Check collision here
    local _, _, cols = bump_world:move(
        entity, world_hitbox.x, world_hitbox.y, check_filter
    )
    if #cols > 0 then
        world("on_collision", cols)
    end
end

function system.update_collection(entity, world)
    for _, hitbox in ipairs(entity[nw.component.hitbox_collection]) do
        system.update_hitbox(hitbox, world, entity)
    end
end

system.on_entity_updated = {

    [nw.component.hitbox] = function(self, entity, pool, previous_value)
        if pool ~= self.hitboxes then return end

        system.update_hitbox(entity, self.world)
    end,

    [nw.component.bump_world] = function(self, entity, pool, prev_bump)
        if pool == self.hitboxes then
            system.remove_hitbox(prev_bump, entity)
            system.create_hitbox(entity, self.world)
        else
            system.remove_collection(prev_bump, entity)
            system.create_collection(entity, self.world)
        end
    end,

    [nw.component.hitbox_collection] = function(self, entity, pool, prev_collection, next_collection)
        if pool ~= self.collections then return end

        local bump_world = entity[nw.component.bump_world]
        system.remove_collection(bump_world, prev_collection)
        system.create_collection(entity, self.world)
    end,

    [nw.component.position] = function(self, entity, pool)
        if pool == self.hitboxes then
            system.update_hitbox(entity, self.world)
        elseif pool == self.collections then
            system.update_collection(entity, self.world)
        end
    end
}

function system.remove_hitbox(bump_world, entity)
    bump_world:remove(entity)
end

function system.remove_collection(bump_world, collection)
    for _, hitbox in ipairs(collection) do
        system.remove_hitbox(bump_world, hitbox)
    end
end

function system:on_entity_removed(entity, pool, component, value)
    local bump_world = entity[nw.component.bump_world] or value

    if pool == self.hitboxes then
        system.remove_hitbox(bump_world, entity)
    elseif pool == self.collisions then
        local collection = entity[nw.component.bump_world] or value
        system.remove_collection(bump_world, collection)
    end
end

function system.show()
    system.__debug_draw = true
end

function system.hide()
    system.__debug_draw = false
end

local function move_hitbox(entity, dx, dy, move_filter)
    local bump_world = entity[nw.component.bump_world]

    if not bump_world or not bump_world:hasItem(entity) then return dx, dy, {} end
    local x, y = bump_world:getRect(entity)
    local ax, ay, cols = bump_world:move(
        entity, x + dx, y + dy, move_filter or system.default_move_filter
    )

    return ax - x, ay - y, cols
end

local function move_collection(entity, dx, dy)
    local bump_world = entity[nw.component.bump_world]
    local collection = entity[nw.component.hitbox_collection]
    if not bump_world or not collection then return {} end
    local cols = {}

    for _, hitbox in ipairs(collection) do
        local x, y = bump_world:getRect(hitbox)
        local _, _, sub_col = bump_world:move(
            hitbox, x + dx, y + dy, move_filter
        )
        for _, c in ipairs(sub_col) do table.insert(cols, c) end
    end

    return cols
end

function system.move_to(entity, x, y, move_filter)
    local px, py = entity:ensure(nw.component.position):unpack()
    local dx, dy = x - px, y - py
    local dx, dy, dst = system.move(entity, dx, dy, move_filter)
    return px + dx, py + dy, dst
end

function system.move(entity, dx, dy, move_filter)
    local dst = {}
    local dx, dy, hitbox_collisions = move_hitbox(entity, dx, dy, move_filter)
    local collection_collisions = move_collection(entity, dx, dy)

    for _, col in ipairs(hitbox_collisions) do table.insert(dst, col) end
    for _, col in ipairs(collection_collisions) do table.insert(dst, col) end

    -- TODO Change this to use map when collsiion has been refactored
    local pos = entity[nw.component.position]
    entity[nw.component.position] = nw.component.position(
        pos.x + dx, pos.y + dy
    )

    if entity.world then
        entity.world("on_moved", entity, dx, dy)
        if #dst > 0 then entity.world("on_collision", dst) end
    end

    return dx, dy, dst
end

function system.get_rect(entity)
    local bump_world = entity[nw.component.bump_world]

    if not bump_world or not bump_world:hasItem(entity) then return end

    return spatial(bump_world:getRect(entity))
end

function system.check_rect(entity, rect, filter)
    local bump_world = entity[nw.component.bump_world]

    if not bump_world then return {} end

    local x, y, w, h = rect:unpack()
    return bump_world:queryRect(x, y, w, h, filter)
end

return system
