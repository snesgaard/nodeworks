local nw = require "nodeworks"
local T = nw.third.knife.test
local collision = nw.system.collision

T("collision", function(T)
    local world = nw.ecs.world()
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    local hitbox = spatial(0, 0, 100, 100)
    local x, y = 10, 20

    T("assemble", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )

        T:assert(entity:has(nw.component.hitbox))
        T:assert(entity:has(nw.component.position))
        T:assert(entity:has(nw.component.bump_world))

        T:assert(table_equal(entity:get(nw.component.hitbox), hitbox))
        T:assert(table_equal(entity:get(nw.component.position), vec2(x, y)))
        T:assert(entity:get(nw.component.bump_world) == bump_world)
    end)

    T("move", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )

        local ax, ay, cols = collision():move(entity, 10, 20)

        T:assert(ax == 10)
        T:assert(ay == 20)
        T:assert(#cols == 0)
        T:assert(table_equal(entity:get(nw.component.position), vec2(20, 40)))
    end)

    T("move_to", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )

        local ax, ay, cols = collision():move_to(entity, 20, 40)

        T:assert(ax == 20)
        T:assert(ay == 40)
        T:assert(#cols == 0)
        T:assert(table_equal(entity:get(nw.component.position), vec2(20, 40)))
    end)

    T("move_with_collision", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )
        local block = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, 200, hitbox, bump_world
            )

        T:assert(entity:get(nw.component.position).x == x)
        T:assert(entity:get(nw.component.position).y == y)
        T:assert(block:get(nw.component.position).x == x)
        T:assert(block:get(nw.component.position).y == 200)

        local ax, ay, cols = collision():move_to(entity, x, 400)

        T:assert(ax == x)
        T:assert(ay ~= 400)
        T:assert(#cols == 1)
    end)

    T("move_with_cross", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )
        local block = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, 200, hitbox, bump_world
            )

        local ax, ay, cols = collision():move_to(
            entity, x, 400,
            function() return "cross" end
        )

        T:assert(ax == x)
        T:assert(ay == 400)
        T:assert(#cols == 1)
    end)

    T("move_with_ignore", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )
        local block = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, 200, hitbox, bump_world
            )

        local ax, ay, cols = collision():move_to(
            entity, x, 400,
            function() return false end
        )

        T:assert(ax == x)
        T:assert(ay == 400)
        T:assert(#cols == 0)
    end)

    --[[
    T("move_body", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )

        local ax, ay, colinfo = collision():move_body_to(entity, 20, 30)

        T:assert(#colinfo == 0)
        T:assert(table_equal(
            entity:get(nw.component.hitbox),
            spatial(20, 30, hitbox.w, hitbox.h)
        ))
    end)
    ]]--

    local function test_system(ctx)
        ctx.moved = ctx:listen("moved"):latest()

        ctx.collision = ctx:listen("collision"):latest()

        while ctx:is_alive() do ctx:yield() end
    end

    T("events_moved", function(T)
        local ctx = world:push(test_system)

        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )

        local ax, ay, cols = collision(ctx):move(entity, 10, 20)

        world:spin()
        T:assert(ctx.moved:peek() == entity)
    end)

    T("events_collision", function(T)
        local ctx = world:push(test_system)

        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, y, hitbox, bump_world
            )
        local block = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                x, 200, hitbox, bump_world
            )

        local ax, ay, cols = collision(ctx):move(entity, 0, 300)
        world:spin()
        T:assert(ctx.moved:peek() == entity)
        T:assert(ctx.collision:peek().item == entity.id)
        T:assert(ctx.collision:peek().ecs_world == entity:world())
    end)

    T("cleanup", function(T)
        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                200, 300, hitbox, bump_world
            )
        T:assert(bump_world:hasItem(entity.id))
        entity:destroy()
        T:assert(not bump_world:hasItem(entity.id))
    end)

    T("move_body", function(T)
        local pos = vec2(200, 300)

        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                pos.x, pos.y, hitbox, bump_world
            )

        collision():move_hitbox(entity, 0, 0)
        T:assert(
            table_equal(
                entity:get(nw.component.hitbox),
                hitbox
            )
        )
        T:assert(
            table_equal(
                entity:get(nw.component.position), pos
            )
        )

        collision():move_hitbox(entity, 20, 0)
        T:assert(
            table_equal(
                entity:get(nw.component.hitbox),
                hitbox:move(20, 0)
            )
        )
        T:assert(
            table_equal(
                entity:get(nw.component.position), pos
            )
        )

        collision():move_hitbox(entity, 0, 30)
        T:assert(
            table_equal(
                entity:get(nw.component.hitbox),
                hitbox:move(20, 30)
            )
        )
        T:assert(
            table_equal(
                entity:get(nw.component.position), pos
            )
        )
    end)

    T("move_body_w_obstacle", function(T)
        local hitbox = spatial(0, 0, 10, 10)

        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                0, 0, hitbox, bump_world
            )
        local block = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                100, 0, hitbox, bump_world
            )

        collision():move_hitbox(entity, 200, 0)

        T:assert(
            table_equal(
                entity:get(nw.component.hitbox),
                hitbox:move(200, 0)
            )
        )
        T:assert(
            table_equal(
                entity:get(nw.component.position),
                vec2(-110, 0)
            )
        )
    end)

    T("mirror", function(T)
        local hitbox = spatial(20, 0, 10, 10)

        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                0, 0, hitbox, bump_world
            )

        collision():mirror(entity)

        T:assert(entity:get(nw.component.mirror))

        local bump_hitbox = spatial(bump_world:getRect(entity.id))
        T:assert(
            table_equal(
                bump_hitbox, hitbox:hmirror()
            )
        )
    end)

    T("mirror_with_obstacle", function(T)
        local hitbox = spatial(20, 0, 10, 10)

        local entity = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                0, 0, hitbox, bump_world
            )
        local block = ecs_world:entity()
            :assemble(
                collision().assemble.init_entity,
                0, 0, spatial(-10, 0, 10, 10), bump_world
            )

        local col_info = collision():mirror(entity)

        T:assert(entity:get(nw.component.mirror))
        T:assert(#col_info == 1)

        local bump_hitbox = spatial(bump_world:getRect(entity.id))
        T:assert(table_equal(bump_hitbox, spatial(0, 0, 10, 10)))
        T:assert(table_equal(entity:get(nw.component.position), vec2(30, 0)))
    end)
end)
