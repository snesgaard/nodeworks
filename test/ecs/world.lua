local nw = require "nodeworks"
local T = nw.third.knife.test

local components = {}

function components.a(value) return value or 1 end
function components.b(value) return value or 2 end
function components.was_pushed(val) return val or 0 end

local system_a = nw.ecs.system(components.a, components.b)

function system_a.on_pushed(world, pool)
    world:singleton()
        :set(
            components.was_pushed,
            world:singleton():ensure(components.was_pushed) + 1
        )
end

function system_a.on_poped(world, pool)
    world:singleton()
        :set(
            components.was_pushed,
            world:singleton():ensure(components.was_pushed) - 1
        )
end

function system_a.add_with_repeat(world, pool, value)
    for _, entity in ipairs(pool) do
        entity[components.a] = entity[components.a] + value
    end

    world:event("add", value)
end

function system_a.add(world, pool, value)
    for _, entity in ipairs(pool) do
        entity[components.a] = entity[components.a] + value
    end
end

local system_b = nw.ecs.system(components.b)

function system_b.add(world, pool, value)

end

local scene = {}

function scene.on_push(ctx)
    ctx.a = ctx:entity()
        :set(components.a)
        :set(components.b)

    ctx.b = ctx:entity()
        :set(components.b)
end

T("ecs.world", function(T)
    local world = nw.ecs.world{system_a, system_b}
    world:push(scene)
    local ctx = world:find(scene)

    T("spawn entity", function(T)
        -- needs to be 3 because of the spawned entties and the singleton
        T:assert(#ctx.dirty_entities == 3)

        ctx:handle_dirty()

        T:assert(#ctx.dirty_entities == 0)
        T:assert(#ctx.entities == 3)

        ctx.b:set(components.a)

        T:assert(#ctx.dirty_entities == 1)
        T:assert(#ctx.entities == 3)

        ctx:handle_dirty()

        T:assert(#ctx.dirty_entities == 0)
        T:assert(#ctx.entities == 3)
    end)

    ctx:handle_dirty()

    T("push", function(T)
        T:assert(ctx.pools[system_a]:size() == 1)
        T:assert(ctx.pools[system_b]:size() == 2)

        T:assert(ctx:singleton():has(components.was_pushed))
        T:assert(ctx:singleton():get(components.was_pushed) == 1)
    end)

    T("pop", function(T)
        world:pop()
        T:assert(world.scene_stack:size() == 0)
    end)

    T("event", function(T)
        local value = 2
        world:event("add_with_repeat", value)
        T:assert(ctx.a:get(components.a) == components.a() + value * 2)
    end)

    T("cache", function(T)
        T:assert(world:from_cache("foo"):peek() == nil)
        world:to_cache("foo", 1)
        T:assert(world:from_cache("foo"):peek() == 1)
    end)
end)
