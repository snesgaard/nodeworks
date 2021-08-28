local function collision_record_component() return {} end

local system = ecs.system(collision_record_component)

local function register_collision(world, item, other, colinfo)
    local record = item:ensure(collision_record_component)
    if not record[other] then
        world("on_contact_begin", item, other, colinfo)
    end
    record[other] = 1
end

local function update_entity(world, entity)
    local record = entity[collision_record_component]
    local there_was_values = false
    for other, value in pairs(record) do
        there_was_values = true
        if value <= 0 then
            record[other] = nil
            world("on_contact_end", entity, other)
        else
            record[other] = value - 1
        end
    end

    if not there_was_values then
        entity:remove(collision_record_component)
    end
end

function system:on_collision(collisions)
    for _, colinfo in ipairs(collisions) do
        local item = colinfo.item
        local other = colinfo.other
        register_collision(self.world, item, other, colinfo)
        register_collision(self.world, other, item, colinfo)
    end
end

function system:update(dt)
    List.foreach(self.pool, function(entity) update_entity(self.world, entity) end)
end

return system
