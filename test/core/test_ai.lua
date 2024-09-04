local nw = require "nodeworks"
local ai = nw.ai

---@module "3rd"
local third = require "3rd"
local T = third.test

local stack = nw.ecs.stack

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
    stack.clear()

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
        nw.system.time.update(1.0)
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

    T("parallel-any", function(T)
        local control = {}

        local bt = ai.parallel_any {
            ai.sequence {
                ai.wait_until(
                    ai.condition(function() return control.a ~= nil end)
                ),
                ai.condition(function() return control.a end)
            },
            ai.sequence {
                ai.wait_until(
                    ai.condition(function() return control.b ~= nil end)
                ),
                ai.condition(function() return control.b end)
            },
        }

        T("pending", function(T)
            T:assert(ai.run(bt) == "pending")
        end)

        T("fail", function(T)
            control.a = false
            control.b = false
            T:assert(ai.run(bt) == "failure")
        end)

        T("a", function(T)
            T("fail", function(T)
                control.a = false
                T:assert(ai.run(bt) == "pending")
            end)
            T("success", function(T)
                control.a = true
                T:assert(ai.run(bt) == "success")
            end)
        end)

        T("b", function(T)
            T("fail", function(T)
                control.b = false
                T:assert(ai.run(bt) == "pending")
            end)
            T("success", function(T)
                control.b = true
                T:assert(ai.run(bt) == "success")
            end)
        end)
    end)

    T("parallel_all", function(T)
        local control = {}

        local bt = ai.parallel_all {
            ai.sequence {
                ai.wait_until(
                    ai.condition(function() return control.a ~= nil end)
                ),
                ai.condition(function() return control.a end)
            },
            ai.sequence {
                ai.wait_until(
                    ai.condition(function() return control.b ~= nil end)
                ),
                ai.condition(function() return control.b end)
            },
        }

        T("pending", function(T)
            T:assert(ai.run(bt) == "pending")
        end)

        T("fail", function(T)
            control.a = false
            control.b = false
            T:assert(ai.run(bt) == "failure")
        end)

        T("success", function(T)
            control.a = true
            control.b = true
            T:assert(ai.run(bt) == "success")
        end)

        T("a", function(T)
            T("fail", function(T)
                control.a = false
                T:assert(ai.run(bt) == "failure")
            end)
            T("success", function(T)
                control.a = true
                T:assert(ai.run(bt) == "pending")
            end)
        end)

        T("b", function(T)
            T("fail", function(T)
                control.b = false
                T:assert(ai.run(bt) == "failure")
            end)
            T("success", function(T)
                control.b = true
                T:assert(ai.run(bt) == "pending")
            end)
        end)        
    end)

    T("defer", function(T)
        T("on-success-and-pending", function(T)
            local a = {value = 0}
            local bt = ai.sequence {
                ai.action(function() a.value = a.value + 1 end),
                ai.defer(function() a.value = a.value - 1 end),
                ai.wait_until(
                    ai.condition(function() return a.go end)
                ),
                ai.action(function() a.done = true end)
            }
            T:assert(ai.run(bt) == "pending")
            T:assert(a.value == 1)
            a.go = true
            T:assert(ai.run(bt) == "success")
            T:assert(a.done)
            T:assert(a.value == 0)
        end)
        T("on-failure", function(T)
            local a = {value = 0}
            local bt = ai.sequence {
                ai.action(function() a.value = a.value + 1 end),
                ai.defer(function() a.value = a.value - 1 end),
                ai.condition(function() return false end),
                ai.defer(function() a.value = a.value - 1 end)
            }
            T:assert(ai.run(bt) == "failure")
            T:assert(a.value == 0)
        end)
        T("partial-sequence", function(T)
            local a = {}
            local bt = ai.sequence {
                ai.defer(function() a.foo = true end),
                ai.wait_until(ai.condition(function() end)),
                ai.defer(function() a.bar = true end)
            }
            T:assert(ai.run(bt) == "pending")
            T:assert(not a.foo)
            T:assert(not a.bar)

            ai.reset(bt)

            T:assert(a.foo)
            T:assert(not a.bar)
        end)
    end)
end)