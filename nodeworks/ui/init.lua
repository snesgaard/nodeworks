local nw = require "nodeworks"

local ui = {}
ui.__index = ui

local BASE = ...

function ui:layer_pool()
    return self.world:singleton():ensure(ui.ui_state, self.world) % nw.component.layer_pool
end

function ui.ui_state(world)
    return world:entity()
        :set(nw.component.layer_type, "entitygroup")
        :set(nw.component.layer_pool)
        :set(nw.component.flush_on_draw)
end

function ui:state(id)
    local w = self.widget_state[id]
    if w then return w end
    local w = nw.ecs.entity()
    self.widget_state[id] = w
    return w
end

function ui:position(id, x, y)
    self:state(id):set(nw.component.position, x, y)
    return self
end

function ui:set_input(input_buffer)
    self.input_buffer = input_buffer
    return self
end

function ui:input()
    return self.input_buffer or self.world:singleton()
end

function ui:set_style(style)
    self.style = style
    return self
end

ui.menu = require(BASE .. ".menu")

return function(world, style)
    return setmetatable(
        {style = style, world = world, widget_state = {}},
        ui
    )
end
