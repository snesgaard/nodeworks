local nw = require "nodeworks"
local T = nw.third.knife.test

local function component_a(v) return v end

T("entity", function(T)
    local ecs_world = nw.ecs.entity.create()
    local id = "id"

    T("set", function(T)
        ecs_world:set(component_a, id, 2)
        T:assert(ecs_world:get(component_a, id) == 2)
    end)

    T("entity_persistence", function(T)
        T:assert(ecs_world:entity(id) == ecs_world:entity(id))
    end)

    T("copy_on_write", function(T)
        -- First set a value
        ecs_world:set(component_a, id, 2)
        -- Then create a copy
        local ecs_world_copy = ecs_world:copy()
        -- Assert that both the values and the tables are the same in both worlds
        T:assert(
            ecs_world_copy:get(component_a, id) == ecs_world:get(component_a, id)
        )
        T:assert(
            ecs_world_copy:get_component_table(component_a) == ecs_world:get_component_table(component_a)
        )
        -- Now write a new value into the copy
        ecs_world_copy:set(component_a, id, 3)
        -- Assert that values in both are different
        T:assert(
            ecs_world_copy:get(component_a, id) ~= ecs_world:get(component_a, id)
        )
        T:assert(
            ecs_world_copy:get_component_table(component_a) ~= ecs_world:get_component_table(component_a)
        )

        -- Next try to write a new value again in the copy.
        -- Verify that the component table has been retained.
        local prev_comp_table = ecs_world_copy:get_component_table(component_a)
        ecs_world_copy:set(component_a, id, 4)
        T:assert(
            ecs_world_copy:get_component_table((component_a)) == prev_comp_table
        )
    end)
end)
