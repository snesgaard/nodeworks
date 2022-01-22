local nw = require "nodeworks"

local layer = {}
layer.__index = layer

function layer:draw()
    for i = #self.entities, 1, -1 do
        nw.system.render.draw_entity(self.entities[i])
    end
end

function layer:rectangle(rect)
    local e = nw.ecs.entity()
        :set(nw.component.drawable, "rectangle")
        :set(nw.component.rectangle, rect)
    table.insert(self.entities, e)
    return e
end

return function()
    return setmetatable(
        {
            entities = {}
        },
        layer
    )
end
