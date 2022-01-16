local nw = require "nodeworks"
local T = nw.third.knife.test

T("focus", function(T)
    local focus = nw.nodegui.focus()

    focus:push("foo")

    T("basic", function(T)
        T:assert(focus:has("foo"))
        T:assert(not focus:has("bar"))
        T:assert(not focus:has("baz"))

        T:assert(focus:peek() == "foo")
    end)

    focus:push("bar")

    T("two", function(T)
        T:assert(focus:has("foo"))
        T:assert(focus:has("bar"))
        T:assert(not focus:has("baz"))

        T:assert(focus:peek() == "bar")
    end)

    T("pop", function(T)
        local pop_id = focus:pop()

        T:assert(pop_id == "bar")

        T:assert(focus:has("foo"))
        T:assert(not focus:has("bar"))
        T:assert(not focus:has("baz"))

        T:assert(focus:peek() == "foo")
    end)
end)
