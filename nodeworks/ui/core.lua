local nw = require "nodeworks"

local core = {}
core.__index = {}

function core:register_api(name, func)
    self[name] = func
    return self
end

function core:state(id)
    if self.widget_state[id] then return self.widget_state[id] end
    local w = nw.ecs.entity()
    self.widget_state[id] = w
    return w
end

function core.set_style()

return function(world)
    return setmetatable(
        {
            world = world,
            widget_state = {}
        },
        core
    )
end
