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
        :set(nw.component.position, 30, 40)

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

    T("slices", function(T)
        local slices = {
            body = spatial(0, 0, 20, 10),
            attack = spatial(0, 0, 10, 20)
        }

        nw.system.animation().update_slices(entity, slices)

        local relation = nw.system.animation().component.animation_slice:ensure(entity.id)

        local entity_slices = ecs_world:get_component_table(relation)
        T:assert(entity_slices:size() == 2)

        T("destroy", function(T)
            entity:destroy()
            local entity_slices = ecs_world:get_component_table(relation)
            T:assert(entity_slices:size() == 0)
        end)

    end)
end)
