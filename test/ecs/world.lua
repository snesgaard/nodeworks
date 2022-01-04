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

T("ecs.world", function(T)
    world = nw.ecs.world()

    local a = world:entity()
        :set(components.a)
        :set(components.b)

    local b = world:entity()
        :set(components.b)

    T("spawn entity", function(T)
        T:assert(#world.changed_entities == 2)

        world:resolve_changed_entities()

        T:assert(#world.changed_entities == 0)
        T:assert(#world.entities == 2)

        b:set(components.a)

        T:assert(#world.changed_entities == 1)
        T:assert(#world.entities == 2)

        world:resolve_changed_entities()

        T:assert(#world.changed_entities == 0)
        T:assert(#world.entities == 2)
    end)

    world:resolve_changed_entities()
    local system_group = {system_a, system_b}
    world:push(system_group)

    T("push", function(T)
        T:assert(world.system_stack:size() == 1)
        T:assert(world.system_stack[1] == system_group)

        T:assert(world:get_pool(system_a):size() == 1)
        T:assert(world:get_pool(system_b):size() == 2)

        T:assert(world:singleton():has(components.was_pushed))
        T:assert(world:singleton():get(components.was_pushed) == 1)
    end)

    T("pop", function(T)
        world:pop()
        T:assert(world.system_stack:size() == 0)

        T:assert(world:get_pool(system_a):size() == 0)
        T:assert(world:get_pool(system_b):size() == 0)

        T:assert(world:singleton():has(components.was_pushed))
        T:assert(world:singleton():get(components.was_pushed) == 0)

        world:pop()
    end)

    T("event", function(T)
        local value = 2
        world:event("add_with_repeat", value)
        T:assert(a:get(components.a) == components.a() + value * 2)
    end)

end)
