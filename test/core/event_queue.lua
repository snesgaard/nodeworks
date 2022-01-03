local nw = require "nodeworks"
local T = nw.third.knife.test

T("event_queue", function(T)
    local foo = "foo"

    local function bar()
        foo = foo .. "bar"
    end
    local function baz()
        foo = foo .. "baz"
    end
    local function append_to_foo(text)
        foo = foo .. text
    end

    local eq = event_queue()

    T("simple_spin", function(T)
        eq:add_without_spin(bar):add_without_spin(baz):spin()
        T:assert(foo == "foobarbaz")
    end)

    T("recursive_spin", function(T)
        local function bar_with_baz() eq:add(bar):add(baz) end
        eq(bar_with_baz)
        T:assert(foo == "foobarbaz", foo)
    end)

    T("spin with args", function(T)
        eq
            :add_without_spin(append_to_foo, "gnu")
            :add_without_spin(append_to_foo, "hest")
            :spin()
        T:assert(foo == "foognuhest")
    end)
end)
