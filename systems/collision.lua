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
    return ""
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
    world("on_collision", parent_entity, entity, cols)
end

function system.create_collection(entity, world)
    local colletion = entity[components.hitbox_collection]
    if not colletion then return end
    for _, hitbox in ipairs(colletion) do
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
    world("on_collision", parent_entity, entity, cols)
end

function system.update_collection(entity, world)
    for _, hitbox in ipairs(entity[components.hitbox_collection]) do
        system.update_hitbox(hitbox, world, entity)
    end
end

system.on_entity_updated = {

    [components.hitbox] = function(self, entity, pool, previous_value)
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

    [components.hitbox_collection] = function(self, entity, pool, prev_collection)
        local bump_world = entity[components.bump_world]
        system.remove_collection(bump_world, prev_collection)
        system.create_collection(entity, self.world)
    end,

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


return system
