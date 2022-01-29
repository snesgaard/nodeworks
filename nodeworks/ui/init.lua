local nw = require "nodeworks"

local ui = {}

local BASE = ...

function ui.__index(t, k)
    return require(BASE .. "." .. k)
end

function ui.register_input_handler(world, ...)
    local state = world:singleton():ensure(ui.ui_state, world)
    local delegate_queue = state % nw.component.delegate_queue
    table.insert(delegate_queue, {...})
end

function ui.layer_pool(world)
    return world:singleton():ensure(ui.ui_state, world) % nw.component.layer_pool
end

function ui.ui_state(world)
    return nw.ecs.entity(world)
        :set(nw.component.layer_type, "entitygroup")
        :set(nw.component.layer_pool)
        :set(nw.component.flush_on_draw)
        :set(nw.component.delegate_queue)
        :set(nw.component.delegate_order, "back_to_front")
end

return setmetatable(ui, ui)
