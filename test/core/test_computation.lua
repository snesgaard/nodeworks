local nw = require "nodeworks"
local T = nw.third.knife.test

local function add(a, b) return a + b end

local function mutliply(a, b) return a * b end

local function test_compute(a)
    local b = coroutine.yield()
    return nw.compute.enter(add, a, b)
end

local function test_compute_2(a)
    local b = coroutine.yield()
    local c = nw.compute.enter(add, a, b)
    local d = coroutine.yield()
    return nw.compute.enter(mutliply, c, d)
end


T("computation", function(T)
    T("single_add", function(T)
        local status = nw.compute(test_compute, 1)
    
        T:assert(status:is_pending())
        T:assert(not status:is_success())
        T:assert(not status:is_failure())
        T:assert(status:peek_record():size() == 0)
    
        local status = status:resume(2)
    
        T:assert(not status:is_pending())
        T:assert(status:is_success())
        T:assert(not status:is_failure())
        T:assert(status:peek_record():size() == 1)
    
        local info = status:peek_record():unpack()
        T:assert(info.func == add)
    end)

    T("add_multiply", function(T)
        local status = nw.compute(test_compute_2, 1)
            :resume(2)
            :resume(3)

        T:assert(status:is_success())
        T:assert(status:values() == 9)
        T:assert(
            status:peek_record():map(function(r) return r.func end)
            ==
            list(add, mutliply)
        )
    end)

    T("error_on_consumed", function(T)
        local status = nw.compute(test_compute_2)
        T:assert(status:resume(2))
        T:error(function() status:resume(2) end)
    end)

    T("garbage_collection", function(T)
        collectgarbage()
        local status = nw.compute(test_compute, 1):resume(2)
        local r = nw.compute.record_storage()
        T:assert(Dictionary.size(r) == 1)
        status = nil
        collectgarbage()
        T:assert(Dictionary.size(r) == 0)
    end)
end)