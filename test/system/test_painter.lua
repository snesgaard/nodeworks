---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local stack = nw.ecs.stack
local painter = nw.system.painter

T("painter", function(T)
    stack.clear()
    
    stack.assemble(
        {
            {nw.component.layer, 1},
            {nw.component.position, 1, 1},
            {nw.component.drawable, "foo"}
        },
        "a"
    )
    stack.assemble(
        {
            {nw.component.layer, 1},
            {nw.component.position, 1, 2},
            {nw.component.drawable, "bar"}
        },
        "b"
    )

    T:assert(painter.compare_entities("a", "b"))

    painter.draw()

    T("manipulate_layer", function(T)
        stack.set(nw.component.layer, "a", 42)
        T:assert(not painter.compare_entities("a", "b"))
    end)
end)