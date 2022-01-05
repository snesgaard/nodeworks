local nw = require "nodeworks"
local T = nw.third.knife.test

T("pool", function(T)
    local A = "A"
    local B = "B"
    local C = "C"
    local D = "D"

    local p1 = pool(A, B, C, D)
    local p2 = p1:remove(A)
    local p3 = p2:remove(B)
    local p4 = p3:add(B)
    local p5 = p1:add(D)
    T("size", function(T)
        T:assert(p1:size() == 4)
        T:assert(p2:size() == 3)
        T:assert(p3:size() == 2)
        T:assert(p4:size() == 3)
        T:assert(p5:size() == 4)
    end)
end)
