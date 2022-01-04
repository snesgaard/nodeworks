local nw = require "nodeworks"
local T = nw.third.knife.test

T("motion", function(T)
    local world = nw.ecs.world()

    local entity = nw.ecs.entity(world)
        + {nw.component.position, 0, 0}
        + {nw.component.velocity, 100, 0}
        + {nw.component.gravity, 10, 0}

    world:push{nw.system.motion}

    T("system members", function(T)
        T:assert(#world:get_pool(nw.system.motion) == 1)
    end)

    local p = entity % nw.component.position
    local v = entity % nw.component.velocity
    local g = entity % nw.component.gravity

    T("simple_move", function(T)
        local dt = 0.5

        local expected_velocity = v + g * dt
        local expected_position = p + v * dt + g * dt * dt

        world("update", dt)

        local position = entity % nw.component.position
        local velocity = entity % nw.component.velocity

        T:assert(isclose(expected_position.x, position.x))
        T:assert(isclose(expected_position.y, position.y))
        T:assert(isclose(expected_velocity.x, velocity.x))
        T:assert(isclose(expected_velocity.y, velocity.y))
    end)

    T("big move!", function(T)
        local dt = 200

        local expected_velocity = v + g * dt
        local expected_position = p + v * dt + g * dt * dt

        world("update", dt)

        local position = entity % nw.component.position
        local velocity = entity % nw.component.velocity

        T:assert(isclose(expected_position.x, position.x))
        T:assert(isclose(expected_position.y, position.y))
        T:assert(isclose(expected_velocity.x, velocity.x))
        T:assert(isclose(expected_velocity.y, velocity.y))
    end)
end)
