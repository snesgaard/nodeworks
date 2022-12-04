local nw = require "nodeworks"
local T = nw.third.knife.test
local result = Result

T("result", function(T)
    T("just", function(T)
        local just = result.just(1)
        T:assert(just:has_value())
        T:assert(not just:has_error())
        T:assert(just:value() == 1)
    end)

    T("error", function(T)
        local error = result.empty("foobar")
        T:assert(error:has_error())
        T:assert(error:message() == "foobar")
    end)

    T("map", function(T)
        T:assert(
            result.just(1):map(function(a) return a + 1 end):value() == 2
        )
    end)

    T("zip", function(T)
        local v = result.just(1) + result.just(2) + result.just(3)
        local r = list(v:value())
        T:assert(r[1] == 1)
        T:assert(r[2] == 2)
        T:assert(r[3] == 3)
    end)

    T("or", function(T)
        T:assert(result.just(1):otherwise(2):value() == 1)
        T:assert(result.error():otherwise(2):value() == 2)
    end)

    T("and_then", function(T)
        local function positive_add(v)
            if v < 0 then
                return result.error()
            else
                return result.just(v + 1)
            end
        end
        T:assert(result.just(1):and_then(positive_add):value() == 2)
        T:assert(result.just(-1):and_then(positive_add):has_error())
    end)
end)
