local nw = require "nodeworks"
local T = nw.third.knife.test

local scene = {}

function scene.on_push(ctx)
    ctx.main = ctx:entity()
        + {nw.component.root_motion}
        + {nw.component.position, 0, 0}
end

T("root_motion", function(T)
    local world = nw.ecs.world{nw.system.root_motion}
    world:push(scene)
    local ctx = world:find(scene)

    T("system members", function(T)
        local pool = ctx.pools[nw.system.root_motion]
        T:assert(#pool == 1)
    end)

    T("simple move", function(T)
        world(
            "on_next_frame",
            ctx.main,
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

        local pos = ctx.main % nw.component.position
        local expected_pos = vec2(10, 0)
        print(pox, expected_pos)
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)

    ctx.main = ctx.main + {nw.component.mirror, true}

    T("mirror move", function(T)
        world(
            "on_next_frame",
            ctx.main,
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

        local pos = ctx.main % nw.component.position
        local expected_pos = vec2(-10, 0)
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)
end)
