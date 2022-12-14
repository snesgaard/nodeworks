local nw = require "nodeworks"
local T = nw.third.knife.test
local Reducer = nw.ecs.reducer

local function add(info, state, num)
    info.name = "add"
    state.value = state.value + num
    info.value = state.value
end

local function sub(info, state, num)
    state.value = state.value - num
    info.name = "sub"
    info.value = state.value
end

local function mul(info, state, num)
    info.name = "mul"
    state.value = state.value * num
end

local function add_then_mul(info, state, a)
    info.add = info:action(add, a)
    info.sub = info:action(mul, a)
end

local function add_then_maybe_zero(info, state, a)
    info.name = "add_then_maybe_zero"
    info.add = info:action(sub, a)
    info.zero = info:maybe_action(function()
        local value = info.add().value
        local num = value < 0 and -value or 0
        return add, num
    end)
end

T("reducer", function(T)
    local reducer = Reducer()

    T("add", function(T)
        local state = {value=0}
        local add_info = reducer(state, add, 1)
        T:assert(state.value == 0 + 1)
    end)

    T("sub", function(T)
        local state = {value=1}
        local sub_info = reducer(state, sub, 2)
        T:assert(state.value == 1 - 2)
    end)

    T("add_then_mul", function(T)
        local state = {value=1}
        local info = reducer(state, add_then_mul, 2)
        T:assert(state.value == (1 + 2) * 2)
    end)

    T("add_then_maybe_zero", function(T)
        local state = {value=0}
        local info = reducer(state, add_then_maybe_zero, 1)
        T:assert(state.value == 0)

        local count = 0
        for i in info:iter() do count = count + 1 end
        T:assert(count == 3)
    end)

    T("post", function(T)
        function reducer.post(info)
            if info:type() == add then info:action(sub, 1) end
        end

        local state = {value=0}
        local info = reducer(state, add, 10)
        T:assert(state.value == 10 - 1)
    end)
end)
