local nw = require "nodeworks"
local T = nw.third.knife.test

local scene = {}

function scene.on_push(ctx)
    ctx.entity = ctx:entity()
        + {nw.component.position, 0, 0}
        + {nw.component.velocity, 100, 0}
        + {nw.component.gravity, 10, 0}
end

T("motion", function(T)
    local world = nw.ecs.world{nw.system.motion}
    world:push(scene)
    local ctx = world:find(scene)

    T("system members", function(T)
        T:assert(#ctx.pools[nw.system.motion] == 1)
    end)

    local p = ctx.entity % nw.component.position
    local v = ctx.entity % nw.component.velocity
    local g = ctx.entity % nw.component.gravity

    T("simple_move", function(T)
        local dt = 0.5

        local expected_velocity = v + g * dt
        local expected_position = p + v * dt + g * dt * dt

        world("update", dt)

        local position = ctx.entity % nw.component.position
        local velocity = ctx.entity % nw.component.velocity

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

        local position = ctx.entity % nw.component.position
        local velocity = ctx.entity % nw.component.velocity

        T:assert(isclose(expected_position.x, position.x))
        T:assert(isclose(expected_position.y, position.y))
        T:assert(isclose(expected_velocity.x, velocity.x))
        T:assert(isclose(expected_velocity.y, velocity.y))
    end)
end)
