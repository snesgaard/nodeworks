local nw = require "nodeworks"
local T = nw.third.knife.test

T("tree", function(T)
    local tree = nw.component.tree()

    local a = "a"
    local b = "b"
    local c = "c"
    local d = "d"

    tree:link(a, b)
    tree:link(a, c)
    tree:link(c, d)

    T:assert(tree:children(a) == list(b, c))
    T:assert(tree:children(b) == list())
    T:assert(tree:children(c) == list(d))

    tree:alias("foo", b)

    T:assert(tree:find("foo") == b)
end)
