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
end)
