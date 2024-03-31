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
end)