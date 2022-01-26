local nw = require "nodeworks"

local rh = {}

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

function rh.register_input_handler(world, ...)
    local state = world:singleton():ensure(rh.ui_state, world)
    local delegate_queue = state % nw.component.delegate_queue
    table.insert(delegate_queue, {...})
end

function rh.layer_pool(world)
    return world:singleton():ensure(rh.ui_state, world) % nw.component.layer_pool
end

function rh.ui_state(world)
    return nw.ecs.entity(world)
        :set(nw.component.layer_type, "entitygroup")
        :set(nw.component.layer_pool)
        :set(nw.component.flush_on_draw)
        :set(nw.component.delegate_queue)
        :set(nw.component.delegate_order, "back_to_front")
end

return setmetatable(rh, rh)
