local nw = require "nodeworks"
local T = nw.third.knife.test
local follow = nw.system.follow()

T("follow", function(T)
    local ecs_world = nw.ecs.entity.create()

    local leader = ecs_world:entity()
        :set(nw.component.position, 0, 0)

    local follower = ecs_world:entity()
        :set(nw.component.position)
        :assemble(follow.follow, leader, 0, 0)
end)
