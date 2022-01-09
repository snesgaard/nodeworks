local nw = require "nodeworks"

local layer_system = nw.ecs.system(nw.component.layer)

function layer_system.on_entity_added(world, entity)
    local layer = entity % nw.component.layer
    layer:ensure(nw.component.layer_pool):add(entity)
end

function layer_system.on_entity_changed(world, entity, past_data)
    local prev_layer = past_data[nw.component.layer]
    local next_layer = entity[nw.component.layer]

    prev_layer:ensure(nw.component.layer):remove(entity)
    next_layer:ensure(nw.component.layer):add(entity)
end

function layer_system.on_entity_removed(world, entity, past_data)
    local layer = entity[nw.component.layer] or past_data[nw.component.layer]
    layer:ensure(nw.component.layer_pool):remove(entity)
end

return layer_system
