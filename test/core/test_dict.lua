---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

---@generic R1, R2
---@param c1 fun(...): R1
---@param c2? fun(...): R2
---@return fun(table: {C1: table<string, R1>, C2: table<string, R2>}, key: string): string, R1, R2
---@return {C1: table<string, R1>, C2: table<string, R2>}
local function view_union(c1, c2)

end

T("dict", function(T)
    T("is_empty", function(T)
        T:assert(nw.dict.is_empty({}))
        T:assert(not nw.dict.is_empty({1}))
    end)

    T("size", function(T)
        T:assert(nw.dict.size({}) == 0)
        T:assert(nw.dict.size({2}) == 1)
        T:assert(nw.dict.size({a = 2, b = 3}) == 2)
    end)

    T("keys", function(T)
        T:assert(nw.list.compare(nw.dict.keys({}), {}))
        T:assert(nw.list.compare(nw.dict.keys({2}), {1}))
        T:assert(nw.list.compare(nw.dict.keys({a = 42}), {"a"}))
    end)

    T("values", function(T)
        T:assert(nw.list.compare(nw.dict.values({}), {}))
        T:assert(nw.list.compare(nw.dict.values({2}), {2}))
        T:assert(nw.list.compare(nw.dict.values({a = 42}), {42}))
    end)

    T("view_union", function(T)
        T("lists", function(T)
            local a = {1, 2, 3}
            local b = {4, 5}
            local c = {7, 6, 5}
    
            local expected = {
                {1, 4, 7},
                {2, 5, 6}
            }
            for k, x, y, w in nw.dict.view_union(a, b, c) do
                local e = expected[k]
                T:assert(e)
                T:assert(x == e[1])
                T:assert(y == e[2])
                T:assert(w == e[3])
            end
        end)
        T("dicts", function(T)
            local a = {a = 3, b = 2, c = 1}
            local b = {a = "a", c = "c"}
            local expected = {
                a = {"a", 3},
                c = {"c", 1}
            }
            for k, x, y in nw.dict.view_union(b, a) do
                local e = expected[k]
                T:assert(e)
                T:assert(x == e[1])
                T:assert(y == e[2])
            end
        end)
    end)
end)