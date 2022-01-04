local nw = require "nodeworks"
local T = nw.third.knife.test

T("Collision", function(T)
    local world = nw.ecs.world{nw.system.collision}
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

    local cross_box = nw.ecs.entity(world, "cross")
        + {nw.component.position, 100, 0}
        + {nw.component.hitbox, 0, 0, 10, 10}
        + {nw.component.bump_world, bump_world}

    world:resolve_changed_entities()

    T("System population", function(T)
        local pool = world:get_pool(nw.system.collision)
        T:assert(#pool == 3)
    end)
    T("bump population", function(T)
        T:assert(bump_world:hasItem(entity))
        T:assert(bump_world:hasItem(box))
        T:assert(bump_world:hasItem(cross_box))
    end)
    T("Test relative motion (collision)", function(T)
        local dx, dy, cols = nw.system.collision.move(entity, 0, 200)
        T:assert(dx == 0)
        T:assert(dy == 90)
        T:assert(#cols == 1)
    end)
    T("Test relative motion (no collision)", function(T)
        local dx, dy, cols = nw.system.collision.move(entity, 0, 50)
        T:assert(dx == 0)
        T:assert(dy == 50)
        T:assert(#cols == 0)
    end)
    T("Test absolute motion (no collision)", function(T)
        local x, y, cols = nw.system.collision.move_to(entity, 0, 50)
        T:assert(x == 0)
        T:assert(y == 50)
        T:assert(#cols == 0)
    end)
    T("Test absolute motion", function(T)
        local x, y, cols = nw.system.collision.move_to(entity, 0, 200)
        T:assert(x == 0)
        T:assert(y == 90)
        T:assert(#cols == 1)
    end)
    T("Cross motion", function(T)
        local x, y, cols = nw.system.collision.move_to(entity, 200, 0)
        T:assert(x == 200)
        T:assert(y == 0)
        T:assert(#cols == 1)
    end)
    T("Remove entity", function(T)
        entity:remove(nw.component.bump_world)
        world:resolve_changed_entities()
        T:assert(not bump_world:hasItem(entity))
    end)
end)
