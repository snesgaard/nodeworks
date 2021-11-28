local nw = require "nodeworks"

local system = nw.ecs.system(nw.component.hitbox, nw.component.bump_world, nw.component.position)

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

local function world_hitbox(entity)
    local hb = entity % nw.component.hitbox
    if not hb then return end
    return aggregate_transform(hb, entity)
end

local function get_move_filter(entity, move_filter)
    return move_filter or system.default_move_filter
end

local function move(entity, dx, dy, move_filter)
    local bump_world = entity % nw.component.bump_world
    -- Get positions in both world and in local frame
    local position = entity:ensure(nw.component.position)

    if not bump_world or not bump_world:hasItem(entity) then
        entity[nw.component.position] = position + vec2(dx, dy)
        return dx, dy, {}
    end

    local world_hb = world_hitbox(entity)

    -- Perform the motion ni bump
    local fx, fy, cols = bump_world:move(
        entity, world_hb.x + dx, world_hb.y + dy,
        get_move_filter(entity, move_filter)
    )

    -- Compute the actual relative motion taken
    local dx_f, dy_f = fx - world_hb.x, fy - world_hb.y
    -- Update local position with the relative motion
    entity[nw.component.position] = position + vec2(dx_f, dy_f)

    -- Broadcast any relevant events
    if entity.world then
        entity.world("on_moved", entity, dx_f, dy_f, cols)
        if #cols > 0 then
            entity.world("on_collision", cols)
        end
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
    local world_position = entity % nw.component.position
    local dx, dy = x - world_position.x, y - world_position.y
    local _, _, fx, fy, cols = move(entity, dx, dy, move_filter)
    return fx, fy, cols
end

system.get_world_hitbox = world_hitbox

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
    if bump_world:hasItem(entity) then bump_world:remove(entity) end
end

return system
