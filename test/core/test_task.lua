local nw = require "nodeworks"
local T = nw.third.knife.test

T("task", function(T)
    T("eq", function(T)
        local item = nw.task(function() end)
        local other = nw.task(function() end)
        T:assert(item == item)
        T:assert(item ~= other)
        T:assert(other == other)
    end)

    T("call", function(T)
        local dst = {}
        local task = nw.task(function()
            dst.called = true
            coroutine.yield(1337)
        end)
        local result = task:resume()
        T:assert(dst.called)
        T:assert(result:value() == 1337)
    end)

    T("is_alive", function(T)
        local task = nw.task(function() end)
        T:assert(task:is_alive())
        task:resume():throw()
        T:assert(not task:is_alive())
    end)

    T("set", function(T)
        local task = nw.task(function() end)
        local id_task = task:set(task._func, task._args:unpack())
        local other_task = task:set(function() end)
        T:assert(id_task == task)
        T:assert(other_task ~= task)
    end)

    T("multi_call_set", function(T)
        local limit = 10

        local function func() for i = 1, limit do coroutine.yield(i) end end

        local task = nw.task(func)
        for i = 1, limit do
            task = task:set(func)
            T:assert(task:resume():value() == i)
        end
    end)

    T("args", function(T)
        local val = 1337
        local function echo(v) coroutine.yield(val) end
        T:assert(nw.task(echo, val):resume():value() == val)
    end)
end)
