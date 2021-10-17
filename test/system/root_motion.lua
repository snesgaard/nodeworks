local nw = require "nodeworks"
local T = nw.third.knife.test

T("root_motion", function(T)
    local world = nw.ecs.world{nw.system.root_motion}

    local entity = nw.ecs.entity(world)
        + {nw.component.root_motion}
        + {nw.component.position, 0, 0}

    T("system members", function(T)
        local pool = world:context(nw.system.root_motion).pool
        T:assert(#pool == 1)
    end)

    T("simple move", function(T)
        world(
            "on_next_frame",
            entity,
            {
                slices = {
                    body = spatial(0, 0, 10, 10)
                }
            },
            {
                slices = {
                    body = spatial(10, 0, 10, 10)
                }
            }
        )

        local pos = entity % nw.component.position
        local expected_pos = vec2(10, 0)
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)

    entity = entity + {nw.component.mirror, true}

    T("mirror move", function(T)
        world(
            "on_next_frame",
            entity,
            {
                slices = {
                    body = spatial(0, 0, 10, 10)
                }
            },
            {
                slices = {
                    body = spatial(10, 0, 10, 10)
                }
            }
        )

        local pos = entity % nw.component.position
        local expected_pos = vec2(-10, 0)
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)
end)
