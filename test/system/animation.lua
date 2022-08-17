local nw = require "nodeworks"
local T = nw.third.knife.test

local animation = nw.system.animation()

local frames = {
    {dt = 1},
    {dt = 2},
    {dt = 3}
}

T("animation", function(T)
    local ecs_world = nw.ecs.entity.create()
    local entity = ecs_world:entity()
    animation:play(entity, frames)

    T:assert(animation:get(entity) == frames[1])

    T("update_0.5", function(T)
        animation:update(0.5, ecs_world)
        T:assert(animation:get(entity) == frames[1])
    end)

    T("update 1.5", function(T)
        animation:update(1.5, ecs_world)
        T:assert(animation:get(entity) == frames[2])
    end)

    T("update 3.5", function(T)
        animation:update(3.5, ecs_world)
        T:assert(animation:get(entity) == frames[3])
    end)

    T("update 100", function(T)
        animation:update(100, ecs_world)
        T:assert(animation:get(entity) == frames[3])
    end)
end)
