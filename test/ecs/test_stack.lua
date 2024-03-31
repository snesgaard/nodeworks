---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local stack = nw.ecs.stack

local component = {}

function component.foo(v) return v or 0 end

T("stack", function(T)
    stack.clear()

    local id = "dafack"

    stack.set(component.foo, id, 22)
    T:assert(stack.get(component.foo, id) == 22)
end)