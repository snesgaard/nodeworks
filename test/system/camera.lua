local nw = require "nodeworks"
local T = nw.third.knife.test

T("camera", function(T)
    local ecs_world = nw.ecs.entity.create()

    local camera = ecs_world:entity()
        :set(nw.component.position, 200, 300)
        :set(nw.component.scale, 3, 2)

    gfx.push()
    nw.system.camera.push_transform(camera)
    gfx.pop()
end)
