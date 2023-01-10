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

    follow.handle_moved(nil, leader, 10, 0, ecs_world)

    T:assert(follower:get(nw.component.position).x == 10)
    T:assert(follower:get(nw.component.position).y == 0)

    T("mirror", function(T)
        follow.handle_mirror(nil, leader, true, ecs_world)
        T:assert(follower:get(nw.component.mirror))
    end)

    T("unfollow", function(T)
        follower:assemble(follow.follow)

        follow.handle_moved(nil, leader, 0, 10, ecs_world)
        T:assert(follower:get(nw.component.position).x == 10)
        T:assert(follower:get(nw.component.position).y == 0)
    end)

    T("second follower", function(T)
        local f = ecs_world:entity()
            :set(nw.component.position)
            :assemble(follow.follow, leader, 0, 0)

        follow.handle_moved(nil, leader, 0, 10, ecs_world)

        T:assert(follower:get(nw.component.position).x == 10)
        T:assert(follower:get(nw.component.position).y == 10)

        T:assert(f:get(nw.component.position).x == 0)
        T:assert(f:get(nw.component.position).y == 10)
    end)

    T("gc", function(T)
        collectgarbage()
        local n1 = follow.follow_component:size()

        for i = 1, 10 do
            local s = ecs_world:entity()
            T:assert(follow.follow_component:ensure(s.id))
            s:destroy()
        end

        collectgarbage()
        local n2 = follow.follow_component:size()
        T:assert(n1 == n2)
    end)
end)
