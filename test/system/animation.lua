local nw = require "nodeworks"
local T = nw.third.knife.test

T("Animation", function(T)
    local world = nw.ecs.world{nw.system.animation}

    local entity = nw.ecs.entity(world)
        + {nw.component.sprite}
        + {nw.component.animation_state}

    world:resolve_changed_entities()

    T("System members", function(T)
        T:assert(#world:get_pool(nw.system.animation) == 1)
    end)
end)
