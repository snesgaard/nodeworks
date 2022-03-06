local nw = require "nodeworks"
local T = nw.third.knife.test

T("pool", function(T)
    local a = {}
    local b = {}
    local c = {}

    local pool = nw.ecs.pool()

    T:assert(pool:add(a))
    T:assert(pool:add(b))
    T:assert(pool:add(c))

    T:assert(pool[a] == 1)
    T:assert(pool[b] == 2)
    T:assert(pool[c] == 3)

    T:assert(pool[1] == a)
    T:assert(pool[2] == b)
    T:assert(pool[3] == c)

    T("remove a", function(T)
        T:assert(pool:remove(a))

        T:assert(pool[a] == nil)

        T:assert(pool[1] == b)
        T:assert(pool[2] == c)

        T:assert(pool[b] == 1)
        T:assert(pool[c] == 2)
    end)

    T("remove b", function(T)
        T:assert(pool:remove(b))

        T:assert(pool[b] == nil)

        T:assert(pool[1] == a)
        T:assert(pool[2] == c)

        T:assert(pool[a] == 1)
        T:assert(pool[c] == 2)
    end)

    T("remove c", function(T)
        T:assert(pool:remove(c))

        T:assert(pool[c] == nil)

        T:assert(pool[1] == a)
        T:assert(pool[2] == b)

        T:assert(pool[a] == 1)
        T:assert(pool[b] == 2)
    end)
end)
