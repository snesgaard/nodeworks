local nw = require "nodeworks"
local T = nw.third.knife.test

T("collision_contact", function(T)
    local world = nw.ecs.world{
        nw.system.collision,
        nw.system.collision_contact
    }

    world.on_event = on_event_test()

    local bump_world = nw.third.bump.newWorld()

    local entity = nw.ecs.entity(world, "entity")
        + {nw.component.position, 0, 0}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}
        + {nw.component.body}

    local box = nw.ecs.entity(world, "box")
        + {nw.component.position, 0, 100}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}
        + {nw.component.body}

    T("simple_contact", function(T)
        nw.system.collision.move(entity, 0, 100)
        T:assert(world.on_event:has("on_contact_begin"))
    end)

    T("simple_contact_none", function(T)
        nw.system.collision.move(entity, 0, 50)
        T:assert(not world.on_event:has("on_contact_begin"))
    end)
end)
