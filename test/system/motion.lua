local nw = require "nodeworks"
local T = nw.third.knife.test

local function system(ctx, ecs_world)
    local update = ctx:listen("update"):collect()
    local collisions = ctx:listen("collision"):collect()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            nw.system.motion(ctx):update(dt, ecs_world)
        end

        for _, colinfo in ipairs(collisions:pop()) do
            nw.system.motion(ctx):on_collision(colinfo)
        end

        ctx:yield()
    end
end

T("motion", function(T)
    local world = nw.ecs.world()
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()
    local actor = ecs_world:entity()
        :assemble(nw.system.collision().assemble.init_entity,
            0, 0, nw.component.hitbox(10, 10), bump_world
        )
        :set(nw.component.velocity, 1, 0)

    local block = ecs_world:entity()
        :assemble(nw.system.collision().assemble.init_entity,
            50, 0, nw.component.hitbox(10, 10), bump_world
        )

    world:push(system, ecs_world)

    T("move_simple", function(T)
        world:emit("update", 1):spin()
        T:assert(actor:get(nw.component.position).x == 1)
        T:assert(actor:get(nw.component.velocity).x == 1)
    end)

    T("move_with_collision", function(T)
        world:emit("update", 100):spin()
        T:assert(actor:get(nw.component.velocity).x == 0)
    end)


    T("gravity", function(T)
        actor:set(nw.component.gravity, 1, 0)
        world:emit("update", 1):spin()
        T:assert(actor:get(nw.component.velocity).x == 2)
    end)
end)
