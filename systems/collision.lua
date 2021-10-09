local nw = require "nodeworks"

local system = nw.ecs.system(nw.component.hitbox, nw.component.bump_world)

local function cross_filter() return "cross" end

function system.default_move_filter(item, other)
    if item[nw.component.body] and other[nw.component.body] then
        return "slide"
    end

    return "cross"
end

local function aggregate_transform(hitbox, entity)
    if entity[nw.component.mirror] then
        hitbox = hitbox:hmirror()
    end
    local pos = entity:ensure(nw.component.position)
    return hitbox:move(pos.x, pos.y)
end

local function world_hitbox(entity, lineage)
    local hb = entity % nw.component.hitbox
    if not hb then return end
    lineage = lineage or nw.system.parenting.lineage(entity)
    local world_hb = lineage:reduce(aggregate_transform, hb)
    return world_hb
end

local function get_move_filter(entity, move_filter)
    if nw.system.parenting.is_child(entity) then return cross_filter end
    return move_filter or system.default_move_filter
end

local function move(entity, dx, dy, move_filter, skip_pos_update)
    local bump_world = entity % nw.component.bump_world
    if not bump_world or not bump_world:hasItem(entity) then return dx, dy, {} end

    -- Get positions in both world and in local frame
    local position = entity:ensure(nw.component.position)
    local world_hb = world_hitbox(entity)

    -- Perform the motion ni bump
    local fx, fy, cols = bump_world:move(
        entity, world_hb.x + dx, world_hb.y + dy,
        get_move_filter(entity, move_filter)
    )

    -- Compute the actual relative motion taken
    local dx_f, dy_f = fx - world_hb.x, fy - world_hb.y
    -- Update local position with the relative motion
    if not skip_pos_update then
        entity[nw.component.position] = position + vec2(dx_f, dy_f)
    end

    -- Broadcast any relevant events
    if entity.world then
        entity.world("on_moved", entity, dx_f, dy_f, cols)
        if #cols > 0 then
            entity.world("on_collision", entity, cols)
        end
    end
    -- Now iterate through all children witht he relative motion
    for _, child in ipairs(nw.system.parenting.children(entity)) do
        move(child, 0, 0, cross_filter, true)
    end

    -- return actual motion
    return dx_f, dy_f, fx, fy, cols
end

function system.move(entity, dx, dy, move_filter)
    local dx_f, dy_f, _, _, cols = move(entity, dx, dy, move_filter)
    return dx_f, dy_f, cols
end

function system.move_to(entity, x, y, move_filter)
    -- First compute the corresponding relative motion
    local world_position = nw.system.parenting.world_position(entity)
    local dx, dy = x - world_position.x, y - world_position.y
    local _, _, fx, fy, cols = move(entity, dx, dy, move_filter)
    return fx, fy, cols
end

function system.move_to_local(entity, x, y, move_filter)
    local position = entity:ensure(nw.component.position)
    local dx, dy = x - position.x, y - position.y
    local _, _, _, _, cols = move(entity, dx, dy, move_filter)
    local p = entity % nw.component.position
    return p.x, p.y, cols
end

function system:on_entity_added(entity)
    local hb = entity % nw.component.hitbox
    local bump_world = entity % nw.component.bump_world
    local world_hb = world_hitbox(entity)
    bump_world:add(entity, world_hb:unpack())
    -- A bit of a hacky way to check for collisions
    move(entity, 0, 0, cross_filter)
end

function system:on_entity_removed(entity, pool, component, prev_value)
    local bump_world = component == nw.component.bump_world and prev_value or (entity % nw.component.bump_world)
    bump_world:remove(entity)
end

function system:on_entity_updated(entity, pool, component, value)
    if component == nw.component.parent then
        move(entity, 0, 0)
    end
end

return system
