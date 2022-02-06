local nw = require "nodeworks"
local T = nw.third.knife.test

local scene = {}

function scene.on_push(ctx)
    ctx.main = ctx:entity(world)
        + {nw.component.sprite}
        + {nw.component.animation_state}
end

T("Animation", function(T)
    local world = nw.ecs.world{nw.system.animation}
    local ctx = world:push(scene):find(scene)

    T("System members", function(T)
        T:assert(#ctx.pools[nw.system.animation] == 1)
    end)
end)
