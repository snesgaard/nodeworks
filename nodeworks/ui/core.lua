local nw = require "nodeworks"

local core = {}
core.__index = core

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

function core:input()
    return self.input_buffer or self.world:singleton()
end

return function(world, input_buffer)
    return setmetatable(
        {
            world = world,
            input_buffer = input_buffer or world:singleton(),
            widget_state = {}
        },
        core
    )
end
