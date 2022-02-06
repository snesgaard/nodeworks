local nw = require "nodeworks"
local T = nw.third.knife.test

local function monitor() return true end

local monitor_system = nw.ecs.system()

function monitor_system.on_contact_begin(world, pool)
    world:singleton():set(monitor)
end

local scene = {}

function scene.on_push(ctx, bump_world)
    ctx.main = ctx:entity("main")
        + {nw.component.position, 0, 0}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}
        + {nw.component.body}

    ctx.box = ctx:entity("box")
        + {nw.component.position, 0, 100}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}
        + {nw.component.body}
end

T("collision_contact", function(T)
    local bump_world = nw.third.bump.newWorld()
    local world = nw.ecs.world{
        nw.system.collision,
        nw.system.collision_contact,
        monitor_system
    }

    local ctx = world:push(scene, bump_world):find(scene)

    ctx:handle_dirty()

    T("simple_contact", function(T)
        nw.system.collision.move(ctx.main, 0, 100)
        T:assert(ctx:singleton():get(monitor))
    end)

    T("simple_contact_none", function(T)
        nw.system.collision.move(ctx.main, 0, 50)
        T:assert(not ctx:singleton():get(monitor))
    end)
end)
