---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local stack = nw.ecs.stack

local component = {}

---@param a integer
function component.bar(a) return a end

function nw.system.behavior.type.foobar(id)
    return nw.ai.sequence {
        nw.ai.set(component.bar, id, 1),
    }
end

T("behavior", function(T)
    stack.clear()

    local id = "me"
    stack.set(nw.component.behavior, id, "foobar")

    nw.system.behavior.spin()
    T:assert(stack.has(nw.component.behavior_instance, id))
    T:assert(stack.get(component.bar, id) == 1)
end)