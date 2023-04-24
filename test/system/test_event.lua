local nw = require "nodeworks"
local T = nw.third.knife.test

local t = setmetatable({}, {__mode="v"})

local component = {}

function component.foo(v) return v or 0 end

T("test_event", function(T)
    local ecs_world = nw.ecs.entity.create()

    T("empty_spin", function(T)
        nw.system.entity():spin(ecs_world)
    end)

    T("single_event", function(T)
        local _, id = nw.system.entity():emit(ecs_world, component.foo, 3)

        nw.system.entity():spin(ecs_world)

        local events = ecs_world:get_component_table(component.foo)
        T:assert(events[id])

        nw.system.entity():spin(ecs_world)

        local events = ecs_world:get_component_table(component.foo)
        T:assert(not events[id])
    end)

    T("create_destroy", function(T)
        local function assemble(entity)
            entity:set(component.foo, 2)
        end

        local id = nw.system.entity():make(ecs_world, assemble)
        nw.system.entity():spin(ecs_world)

        T:assert(ecs_world:get(component.foo, id))

        nw.system.entity():destroy(ecs_world, id)
        nw.system.entity():spin(ecs_world)

        T:assert(not ecs_world:get(component.foo, id))
    end)
end)