local nw = require "nodeworks"
local T = nw.third.knife.test
local tween = nw.system.tween

T("tween", function(T)
    local world = nw.ecs.world()
    local ecs_world = nw.ecs.entity.create()

    local entity = ecs_world:entity():set(nw.component.position, vec2(10, 20))

    tween(world)
        :as(nw.component.position)
        :entity(entity)
        :move_to(vec2(10, 20))
        :assign_to_component()

    T:assert(entity:has(nw.component.position))
    T:assert(table_equal(
        entity:get(nw.component.position), vec2(10, 20)
    ))

    T("move_to", function(T)
        local t = tween(world)
            :as(nw.component.position)
            :entity(entity)
            :move_to(vec2(20, 30), 1)
            :assign_to_component()

        T("half_way", function(T)
            tween(world):update(0.5, ecs_world)

            local p = t:get()
            T:assert(isclose(p.x, 15))
            T:assert(isclose(p.y, 25))
            T:assert(not tween(world):as(nw.component.position):done(entity))
        end)

        T("full", function(T)
            tween(world):update(1, ecs_world)

            local p = t:get()
            T:assert(isclose(p.x, 20))
            T:assert(isclose(p.y, 30))
            T:assert(tween(world):as(nw.component.position):done(entity))
        end)
    end)

    T("warp_to", function(T)
        tween(world)
            :as(nw.component.position)
            :entity(entity)
            :warp_to(vec2(0, 10))
            :assign_to_component()

        local p = entity:get(nw.component.position)
        T:assert(isclose(p.x, 0))
        T:assert(isclose(p.y, 10))
    end)

    T("fancy", function(T)
        local hook = ecs_world:entity()

        local t = tween(world)
            :as(nw.component.position)
            :entity(hook)
            :warp_to(vec2(0, 0))
            :move_to(vec2(150, 150), 1, ease.linear)
            :assign_to_component()

        T:assert(isclose(t:get().x, 0))
        T:assert(isclose(t:get().y, 0))

        tween(world):update(1, ecs_world)

        T:assert(isclose(t:get().x, 150))
        T:assert(isclose(t:get().y, 150))

        T:assert(t:done())
    end)

    T("destroy_on_completion", function(T)
        local t = tween(world)
            :as(nw.component.position)
            :entity(ecs_world:entity())
            :warp_to(vec2(0, 0))
            :move_to(vec2(100, 100), 1, ease.linear)
            :destroy_on_completion()

        T:assert(ecs_world:entity(t.entity.id) == t.entity)
        tween(world):update(1, ecs_world)
        T:assert(ecs_world:entity(t.entity.id) ~= t.entity)
    end)
end)
