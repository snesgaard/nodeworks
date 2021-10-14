local nw = require "nodeworks"
local T = nw.third.knife.test

T("Animation", function(T)
    local world = nw.ecs.world{nw.system.animation}

    local entity = nw.ecs.entity(world)
        + {nw.component.sprite}
        + {nw.component.animation_state}

    T("System members", function(T)
        T:assert(#world:context(nw.system.animation).pool == 1)
    end)
end)
