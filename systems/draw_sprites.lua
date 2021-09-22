local nw = require "nodeworks"

local system = nw.ecs.system(nw.component.sprite)

function system:draw()
    List.foreach(self.pool, systems.sprite.draw)
end

return system
