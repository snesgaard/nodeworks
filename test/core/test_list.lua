---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

T("list", function(T)
    T("map", function(T)
        ---@param x number
        ---@return string
        local function themap(x) return tostring(x) end

        local a = {1, 2, 3, 4, 5}
        local b = nw.list.map(a, themap)

        for i, v in ipairs(b) do
            T:assert(v == themap(a[i]))
        end
    end)

    T("filter", function(T)
        ---@param x number
        ---@return boolean
        local function thefilter(x) return x < 3 end

        local a = {1, 2, 3, 4, 5}
        local b = nw.list.filter(a, thefilter)

        for i, v in ipairs(b) do
            T:assert(thefilter(v))
        end
    end)

    T("reduce", function(T)
        local a = {1, 2, 3}
        local b = nw.list.reduce(a, function(x, y) return x + y end, 0)
        T:assert(b == 6)
    end)

    T("compare", function(T)
        local a = {1, 2, 3}
        local b = {4, 5}
        T:assert(nw.list.compare(a, a))
        T:assert(nw.list.compare(b, b))
        T:assert(not nw.list.compare(a, b))
        T:assert(not nw.list.compare(b, a))
    end)

    T("concat", function(T)
        local a = {1, 2, 3}
        local b = {4, 5, 6}
        local c = nw.list.concat(a, b)
        local expected = {1, 2, 3, 4, 5, 6}
        T:assert(nw.list.compare(c, expected))
    end)
end)