---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

T("spatial", function(T)
    local s = nw.spatial(0, 0, 10, 20)

    T("up", function(T)
        local u = s:up()
        T:assert(u.x == s.x)
        T:assert(u.y == s.y - s.h)
        T:assert(u.w == s.w)
        T:assert(u.h == s.h)
    end)
end)