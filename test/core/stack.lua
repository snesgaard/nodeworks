local nw = require "nodeworks"
local T = nw.third.knife.test

T("stack", function(T)
    local s1 = stack(1, 2, 3)
    local s2 = s1:push(4)
    local s3 = s1:pop()
    local s4 = s1:move(5)

    T("members", function(T)
        T:assert(s1:size() == 3)
        T:assert(s2:size() == 4)
        T:assert(s3:size() == 2)
        T:assert(s4:size() == 3)
    end)

    T("peek", function(T)
        T:assert(s1:peek() == 3)
        T:assert(s2:peek() == 4)
        T:assert(s3:peek() == 2)
        T:assert(s4:peek() == 5)
    end)


    T("foreach", function(T)
        local counter = 0
        local function do_count()
            counter = counter + 1
        end
        s1:foreach(do_count)
        T:assert(counter == 3)
    end)
end)
