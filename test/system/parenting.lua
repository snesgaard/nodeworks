local nw = require "nodeworks"
local T = nw.third.knife.test

T("parenting", function(T)
    local world = nw.ecs.world{nw.system.parenting}

    local parent = nw.ecs.entity(world)

    local child = nw.ecs.entity(world)
        + {nw.component.parent, parent}

    local other_child = nw.ecs.entity(world)
        + {nw.component.parent, parent}

    local grand_child = nw.ecs.entity(world)
        + {nw.component.parent, child}

    world:resolve_changed_entities()

    T("system members", function(T)
        local pool = world:get_pool(nw.system.parenting)
        T:assert(#pool == 3)
    end)

    T("children", function(T)
        local to_test = {
            {parent, {child, other_child}},
            {child, {grand_child}},
            {other_child, {}},
            {grand_child, {}}
        }

        for index, item in ipairs(to_test) do
            local entity, expected_children = unpack(item)
            local children = nw.system.parenting.children(entity)
            local err_string = string.format("child test failed for %i", index)
            T:assert(list_equal(children, expected_children), err_string)
        end
    end)

    T("lineage", function(T)
        local to_test = {
            {parent, {parent}},
            {child, {child, parent}},
            {grand_child, {grand_child, child, parent}},
            {other_child, {other_child, parent}}
        }

        for index, item in ipairs(to_test) do
            local entity, expected_lineage = unpack(item)
            local lineage = nw.system.parenting.lineage(entity)
            local err_string = string.format("lineage test failed for %i", index)
            T:assert(list_equal(lineage, expected_lineage), err_string)
        end

    end)
end)
