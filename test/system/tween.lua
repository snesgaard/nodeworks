local nw = require "nodeworks"
local T = nw.third.knife.test
local tween = nw.system.tween

T("tween", function(T)
    local world = nw.ecs.world()
    local ecs_world = nw.ecs.entity.create()

    local entity = ecs_world:entity():set(nw.component.position, vec2(10, 20))

    tween(world)
        :as(nw.component.position)
        :move_to(entity, vec2(10, 20))
        :update()

    T:assert(entity:has(nw.component.position))
    T:assert(table_equal(
        entity:get(nw.component.position), vec2(10, 20)
    ))

    T("move_to", function(T)
        local t = tween(world)
            :as(nw.component.position)
            :entity(entity)
            :move_to(vec2(20, 30), 1)

        T("half_way", function(T)
            world:emit("update", 0.5):spin()
            local p = t:get()
            T:assert(isclose(p.x, 15))
            T:assert(isclose(p.y, 25))
            T:assert(not tween(world):as(nw.component.position):done(entity))
        end)

        T("full", function(T)
            world:emit("update", 1.0):spin()
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
            :assign(function(entity, value)
                entity:set(nw.component.position, value)
            end)

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
            :update()

        T:assert(isclose(t:get().x, 0))
        T:assert(isclose(t:get().y, 0))

        world:emit("update", 1):spin()

        T:assert(isclose(t:get().x, 150))
        T:assert(isclose(t:get().y, 150))

        T:assert(t:done())
    end)
end)
