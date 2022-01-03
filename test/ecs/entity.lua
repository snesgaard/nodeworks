local nw = require "nodeworks"
local T = nw.third.knife.test


T("entity", function(T)
    local components = {}
    function components.a(val) return val or 1 end
    function components.b(val) return val or 2 end

    local a = nw.ecs.entity()
        :set(components.a)
        :set(components.b)

    local b = nw.ecs.entity()
        :set(components.b)

    T("get", function(T)
        T:assert(a:get(components.a) == components.a())
        T:assert(a:get(components.b) == components.b())

        T:assert(a % components.a == components.a())
        T:assert(a % components.b == components.b())

        T:assert(b:get(components.a) == nil)
        T:assert(b:get(components.b) == components.b())
    end)

    T("changed", function(T)
        T:assert(a:has_changed())
        local past = a:pop_past()
        T:assert(not a:has_changed())

        T:assert(past[components.a] == nil)
        T:assert(past[components.b] == nil)
    end)

    T("past", function(T)
        a:pop_past()
        a:set(components.a, 3):set(components.b, 4)
        T:assert(a:has_changed())
        local past = a:pop_past()
        T:assert(not a:has_changed())

        T:assert(past[components.a] == components.a())
        T:assert(past[components.b] == components.b())
    end)

    T("remove", function(T)
        a:pop_past()
        a:remove(components.a)
        local past = a:pop_past()

        T:assert(a % components.a == nil)
        T:assert(a % components.b == components.b())
        T:assert(past[components.a] == components.a())
    end)

    T("kill", function(T)
        a:pop_past()
        a:destroy()
        T:assert(a:has_changed())
        T:assert(a:is_dead())
    end)
end)
