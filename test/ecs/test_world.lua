---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

---@class SomeClass
---@field hat integer
local SomeClass = nw.misc.class()

function SomeClass:mega() end

local component = {}

function component.foo(a) return a or 1 end

function component.bar(a) return tostring(a) end

---@return SomeClass
function component.baz() return setmetatable({}, SomeClass) end

T("world", function(T)
    local world = nw.ecs.world()
    local id = "id"
    local v = 2

    T:assert(not world:has(component.foo, id))
    T:assert(world:get(component.foo, id) == nil)

    world:set(component.foo, id, v)
    T:assert(world:has(component.foo, id))
    local a = world:get(component.foo, id)
    T:assert(a == component.foo(v))
    world:remove(component.foo, id)

    T:assert(not world:has(component.foo, id))
    T:assert(world:get(component.foo, id) == nil)

    T("gc", function(T)
        local a = nw.ecs.id.weak()
        world:set(component.foo, a)
        T:assert(world:count(component.foo) == 1)
        a = nil
        collectgarbage()
        T:assert(world:count(component.foo) == 0)
    end)
end)