local ai = nw.system.ai
local clock = nw.system.time.clock

function ai.assembly.geq(node)
    return node.a >= node.b and "success" or "failure"
end

function ai.geq(a, b)
    return {
        type = "geq",
        a = a,
        b = b
    }
end

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

    T("wait", function(T)
        local n = ai.wait(0.5)
        T:assert(ai.run(n) == "pending")
        clock.update(1.0)
        T:assert(ai.run(n) == "success")
        T:assert(ai.run(n) == "pending")
    end)

    T("extension", function(T)
        T:assert(ai.run(ai.geq(1, 3)) == "failure")
        T:assert(ai.run(ai.geq(3, 1)) == "success")
    end)

    T("parallel", function(T)
        local dst = {}
        local bt = ai.parallel {
            ai.action(function() dst.a = true end),
            ai.action(function() dst.b = true end)
        }
        local status = ai.run(bt)
        T:assert(status == "success")
        T:assert(dst.a)
        T:assert(dst.b)

        T("concurrent-parallel", function(T)
            local dst = {}
            
            local bt = ai.parallel {
                ai.action(function() dst.a = true end),
                ai.sequence{
                    ai.action(function() dst.b = true end),
                    ai.wait_until(
                        ai.condition(function() return dst.go end)
                    ),
                    ai.action(function() dst.c = true end)
                }
            }

            local status = ai.run(bt)
            T:assert(status == "pending")
            T:assert(dst.a)
            T:assert(dst.b)
            T:assert(not dst.c)

            dst.go = true

            local status = ai.run(bt)
            T:assert(status == "success")
            T:assert(dst.a)
            T:assert(dst.b)
            T:assert(dst.c)
        end)
    end)

end)