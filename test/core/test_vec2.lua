---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"


T("vec2", function(T)
    T("add", function(T)
        local a = nw.vec2(1, 2)
        local b = nw.vec2(3, 4)
        local c = a + b
        T:assert(c.x, a.x + b.x)
        T:assert(c.y, a.y + b.y)
    end)

    T("sub", function(T)
        local a = nw.vec2(1, 2)
        local b = nw.vec2(3, 4)
        local c = a - b
        T:assert(c.x, a.x - b.x)
        T:assert(c.y, a.y - b.y)
    end)

    T("multiply", function(T)
        T("vector", function(T)
            local a = nw.vec2(1, 2)
            local b = nw.vec2(3, 4)
            local c = a * b
            T:assert(c.x, a.x * b.x)
            T:assert(c.y, a.y * b.y)
        end)
    
        T("scalar", function(T)
            local a = nw.vec2(1, 2)
            local s = 3
            local b = a * s
            T:assert(b.x, a.x * s)
            T:assert(b.y, a.y * s)
        end)
    end)

    T("floor", function(T)
        local a = nw.vec2(1.5, 2.5)
        local b = a:floor()
        T:assert(b.x == 1)
        T:assert(b.y == 2)
    end)
end)