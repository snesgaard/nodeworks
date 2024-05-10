local ai = require "nodeworks.core.ai"
local component = require "nodeworks.component"
local stack = require "nodeworks.ecs.stack"

local behavior = {}

function behavior.spin()
    for id, behavior in stack.view_table(component.behavior)
end

return behavior