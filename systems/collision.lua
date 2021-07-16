local system = ecs.system.from_function(
    function(entity)
        return {
            hitboxes = entity:has(
                components.bump_world, components.hitbox, components.position
            ),
            collections = entity:has(
                components.bump_world, components.hitbox_collection,
                components.position
            )
        }
    end
)

local function move_filter(item, other)
    local f = item[components.move_filter] or function() end
    local t = f(item, other)
    if t then
        return t
    elseif item[components.body] and other[components.body] then
        return "slide"
    else
        return "cross"
    end
end

local function check_filter() return "cross" end

function system.transform(hitbox, parent_entity)
    return hitbox:move(parent_entity[components.position]:unpack())
end

function system.create_hitbox(entity, world, parent_entity)
    parent_entity = parent_entity or entity

    local bump_world = parent_entity[components.bump_world]
    local hitbox = entity[components.hitbox]

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
    local colletion = entity[components.hitbox_collection]
    if not colletion then return end
    for _, hitbox in ipairs(colletion) do
        hitbox:add(components.parent, entity)
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
    local bump_world = parent_entity[components.bump_world]
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
    for _, hitbox in ipairs(entity[components.hitbox_collection]) do
        system.update_hitbox(hitbox, world, entity)
    end
end

system.on_entity_updated = {

    [components.hitbox] = function(self, entity, pool, previous_value)
        if pool ~= self.hitboxes then return end

        system.update_hitbox(entity, self.world)
    end,

    [components.bump_world] = function(self, entity, pool, prev_bump)
        if pool == self.hitboxes then
            system.remove_hitbox(prev_bump, entity)
            system.create_hitbox(entity, self.world)
        else
            system.remove_collection(prev_bump, entity)
            system.create_collection(entity, self.world)
        end
    end,

    [components.hitbox_collection] = function(self, entity, pool, prev_collection, next_collection)
        if pool ~= self.collections then return end

        local bump_world = entity[components.bump_world]
        system.remove_collection(bump_world, prev_collection)
        system.create_collection(entity, self.world)
    end,

    [components.position] = function(self, entity, pool)
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
    local bump_world = entity[components.bump_world] or value

    if pool == self.hitboxes then
        system.remove_hitbox(bump_world, entity)
    elseif pool == self.collisions then
        local collection = entity[components.bump_world] or value
        system.remove_collection(bump_world, collection)
    end
end

function system.show()
    system.__debug_draw = true
end

function system.hide()
    system.__debug_draw = false
end

local function move_hitbox(entity, dx, dy)
    local bump_world = entity[components.bump_world]

    if not bump_world then return dx, dy, {} end
    local x, y = bump_world:getRect(entity)
    local ax, ay, cols = bump_world:move(
        entity, x + dx, y + dy, move_filter
    )

    return ax - x, ay - y, cols
end

local function move_collection(entity, dx, dy)
    local bump_world = entity[components.bump_world]
    local collection = entity[components.hitbox_collection]
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

function system.move_to(entity, x, y, frame)
    local pos = entity[components.position]
    local dx, dy = x - pos.x, y - pos.y
    local dx, dy, dst = system.move(entity, dx, dy)
    return pos.x + dx, pos.y + dy, dst
end

function system.move(entity, dx, dy)
    local dst = {}
    local dx, dy, hitbox_collisions = move_hitbox(entity, dx, dy)
    local collection_collisions = move_collection(entity, dx, dy)

    for _, col in ipairs(hitbox_collisions) do table.insert(dst, col) end
    for _, col in ipairs(collection_collisions) do table.insert(dst, col) end

    local pos = entity[components.position]
    pos.x = pos.x + dx
    pos.y = pos.y + dy

    if #dst > 0 and entity.world then
        entity.world("on_collision", dst)
    end

    return dx, dy, dst
end

return system
