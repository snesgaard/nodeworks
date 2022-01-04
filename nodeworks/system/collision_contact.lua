local nw = require "nodeworks"

local function collision_record_component() return {} end

local function collision_record(coltype) return {count=1, type=coltype} end

local system = nw.ecs.system(collision_record_component)

local function register_collision(world, item, other, colinfo)
    local record = item:ensure(collision_record_component)
    local r = record[other]
    if not r then
        world("on_contact_begin", item, other, colinfo)
        record[other] = collision_record(colinfo.type)
    else
        r.count = 1
        if r.type ~= colinfo.type then
            world("on_contact_changed", item, other, colinfo, r.type)
            r.type = colinfo.type
        end
    end
end

local function update_entity(world, entity)
    local record = entity[collision_record_component]
    local there_was_values = false
    for other, r in pairs(record) do
        there_was_values = true
        if r.count <= 0 then
            record[other] = nil
            world("on_contact_end", entity, other)
        else
            r.count = r.count - 1
        end
    end

    if not there_was_values then
        entity:remove(collision_record_component)
    end
end

function system.on_collision(world, pool, collisions)
    for _, colinfo in ipairs(collisions) do
        local item = colinfo.item
        local other = colinfo.other
        register_collision(world, item, other, colinfo)
        register_collision(world, other, item, colinfo)
    end
end

function system.update(world, pool, dt)
    List.foreach(pool, function(entity) update_entity(world, entity) end)
end

return system
