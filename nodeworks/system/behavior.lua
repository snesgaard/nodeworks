local ai = require "nodeworks.core.ai"
local component = require "nodeworks.component"
local stack = require "nodeworks.ecs.stack"

local behavior = {
    ---@type table<string, fun(id: Id): table
    type = {}
}

function behavior.spin()
    for id, behavior_type in stack.view_table(component.behavior) do
        local behavior = stack.ensure(
            component.behavior_instance, id, behavior.type[behavior_type], id
        )
        if behavior then ai.run(behavior) end
    end
end

function behavior.reset(id)
    stack.remove(component.behavior_instance, id)
end

return behavior