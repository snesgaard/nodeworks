local nw = require "nodeworks"
local T = nw.third.knife.test

local scene = {}

function scene.on_push(ctx, bump_world)
    ctx.main = ctx:entity("entity")
        + {nw.component.position, 0, 0}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}
        + {nw.component.body}

    ctx.box = ctx:entity("box")
        + {nw.component.position, 0, 100}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}
        + {nw.component.body}

    ctx.cross_box = ctx:entity("cross")
        + {nw.component.position, 100, 0}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}
end

T("Collision", function(T)
    local world = nw.ecs.world{nw.system.collision}
    local bump_world = nw.third.bump.newWorld()

    world:push(scene, bump_world)

    local ctx = world:find(scene)

    T("System population", function(T)
        local pool = ctx.pools[nw.system.collision]
        T:assert(#pool == 3)
    end)
    T("bump population", function(T)
        T:assert(bump_world:hasItem(ctx.main))
        T:assert(bump_world:hasItem(ctx.box))
        T:assert(bump_world:hasItem(ctx.cross_box))
    end)
    T("Test relative motion (collision)", function(T)
        local dx, dy, cols = nw.system.collision.move(ctx.main, 0, 200)
        T:assert(dx == 0)
        T:assert(dy == 90)
        T:assert(#cols == 1)
    end)
    T("Test relative motion (no collision)", function(T)
        local dx, dy, cols = nw.system.collision.move(ctx.main, 0, 50)
        T:assert(dx == 0)
        T:assert(dy == 50)
        T:assert(#cols == 0)
    end)
    T("Test absolute motion (no collision)", function(T)
        local x, y, cols = nw.system.collision.move_to(ctx.main, 0, 50)
        T:assert(x == 0)
        T:assert(y == 50)
        T:assert(#cols == 0)
    end)
    T("Test absolute motion", function(T)
        local x, y, cols = nw.system.collision.move_to(ctx.main, 0, 200)
        T:assert(x == 0)
        T:assert(y == 90)
        T:assert(#cols == 1)
    end)
    T("Cross motion", function(T)
        local x, y, cols = nw.system.collision.move_to(ctx.main, 200, 0)
        T:assert(x == 200)
        T:assert(y == 0)
        T:assert(#cols == 1)
    end)
    T("Remove entity", function(T)
        ctx.main:remove(nw.component.bump_world)
        ctx:handle_dirty()
        T:assert(not bump_world:hasItem(ctx.main))
    end)
end)
