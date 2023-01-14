local nw = require "nodeworks"
local T = nw.third.knife.test

local frames = {
    {dt = 1, value="a"},
    {dt = 2, value="b"},
    {dt = 3, value="c"}
}

local animation = nw.animation.animation()
    :timeline("frame", nw.animation.sequence(frames))

T("animation", function(T)
    local ecs_world = nw.ecs.entity.create()
    local entity = ecs_world:entity()

    nw.system.animation():play(entity, animation)

    local player = nw.system.animation():player(entity)
    T:assert(player:value().frame == "a")

    T("stop", function(T)
        nw.system.animation():stop(entity)
        T:assert(not nw.system.animation():player(entity))
    end)

    T("update", function(T)
        nw.system.animation():update(1.5, ecs_world)
        T:assert(player:value().frame == "b")
        nw.system.animation():update(2.5, ecs_world)
        T:assert(player:value().frame == "c")
    end)
end)
