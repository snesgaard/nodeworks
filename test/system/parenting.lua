local nw = require "nodeworks"
local T = nw.third.knife.test

local scene = {}

function scene.on_push(ctx)
    ctx.parent = ctx:entity()

    ctx.child = ctx:entity()
        + {nw.component.parent, ctx.parent}

    ctx.other_child = ctx:entity()
        + {nw.component.parent, ctx.parent}

    ctx.grand_child = ctx:entity()
        + {nw.component.parent, ctx.child}
end

T("parenting", function(T)
    local world = nw.ecs.world{nw.system.parenting}
    local ctx = world:push(scene):find(scene)

    T("system members", function(T)
        local pool = ctx.pools[nw.system.parenting]
        T:assert(#pool == 3)
    end)

    T("children", function(T)
        local to_test = {
            {ctx.parent, {ctx.child, ctx.other_child}},
            {ctx.child, {ctx.grand_child}},
            {ctx.other_child, {}},
            {ctx.grand_child, {}}
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
            {ctx.parent, {ctx.parent}},
            {ctx.child, {ctx.child, ctx.parent}},
            {ctx.grand_child, {ctx.grand_child, ctx.child, ctx.parent}},
            {ctx.other_child, {ctx.other_child, ctx.parent}}
        }

        for index, item in ipairs(to_test) do
            local entity, expected_lineage = unpack(item)
            local lineage = nw.system.parenting.lineage(entity)
            local err_string = string.format("lineage test failed for %i", index)
            T:assert(list_equal(lineage, expected_lineage), err_string)
        end

    end)
end)
