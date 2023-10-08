local ai = nw.system.ai

T("ai", function(T)
    stack.reset()

    T("sequence", function(T)
        local dst = {value = 0}
        local function add(v) dst.value = dst.value + v end

        T("add", function(T)
            local s = ai.sequence{
                ai.action(add, 1),
                ai.action(add, 2),
                ai.action(add, 3)
            }

            local status = ai.run(s)

            T:assert(status == "success")
            T:assert(dst.value == 6)
        end)

        T("conditional_add", function(T)
            local s = ai.sequence{
                ai.condition(function() return dst.go end),
                ai.action(add, 1),
                ai.action(add, 2),
            }

            T:assert(ai.run(s) == "failure")
            dst.go = true
            T:assert(ai.run(s) == "success")
            T:assert(dst.value == 3)
        end)

        T("pending_add", function(T)
            local s = ai.sequence {
                ai.action(add, 1),
                ai.wait_until(
                    ai.condition(function() return dst.go end)
                ),
                ai.action(add, 2)
            }

            T:assert(ai.run(s) == "pending")
            T:assert(dst.value == 1)

            T:assert(ai.run(s) == "pending")
            T:assert(dst.value == 1)

            dst.go = true

            T:assert(ai.run(s) == "success")
            T:assert(dst.value == 3)
        end)
    end)

    T("select", function(T)
        local dst = {value=0}

        local function add(v) dst.value = dst.value +v end

        local s = ai.select{
            ai.sequence {
                ai.condition(function() return dst.a end),
                ai.action(add, 1)
            },
            ai.sequence {
                ai.condition(function() return dst.b end),
                ai.action(add, 2)
            }
        }

        T("failure", function(T)
            T:assert(ai.run(s) == "failure")
            T:assert(dst.value == 0)
        end)

        T("branch:a", function(T)
            dst.a = true
            T:assert(ai.run(s) == "success")
            T:assert(dst.value == 1)
        end)

        T("branch:b", function(T)
            dst.b = true
            T:assert(ai.run(s) == "success")
            T:assert(dst.value == 2)
        end)

        T("branch:both", function(T)
            dst.a = true
            dst.b = true
            T:assert(ai.run(s) == "success")
            T:assert(dst.value == 1)
        end)
    end)

    T("invert", function(T)
        local dst = {value = true}

        local n = ai.invert(
            ai.condition(function() return dst.value end)
        )

        T:assert(ai.run(n) == "failure")
        dst.value = false
        T:assert(ai.run(n) == "success")
    end)

    T("wait_until", function(T)
        local dst = {value = false}

        local n = ai.wait_until(
            ai.condition(function() return dst.value end)
        )

        T:assert(ai.run(n) == "pending")
        dst.value = true
        T:assert(ai.run(n) == "success")
    end)
end)