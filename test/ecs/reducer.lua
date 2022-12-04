local nw = require "nodeworks"
local T = nw.third.knife.test
local Reducer = nw.ecs.reducer
local epoch = Reducer.epoch

local component = {}

function component.value(v) return v or 0 end

local function add(state, id, b)
    state:map(component.value, id, function(a) return a + b end)
    return state, {value=b}
end

local function add_and_repeat(state, id, a)
    local actions = list(
        {add, id, a, alias="prev_add"},
        function(record)
            local value = record
                :maybe_info_from_alias("prev_add")
                :map(function(info) return info.value end)
                :value_or_default(0)
            return {add, id, value}
        end
    )

    return state, {}, actions
end

local function multiply(num, val) return num * val end

local function factorial(num, next_val)
    local actions = list(
        {multiply, next_val},
        {factorial, next_val - 1}
    )
    if next_val > 0 then return num, {}, actions end
    return num
end

local function type_from_action(action) return action[1] end

T("reducer", function(T)
    local state = nw.ecs.entity.create()
    local id = "id"
    local reducer = nw.ecs.reducer.create()

    state:set(component.value, id, 1)

    T("simple_add", function(T)
        local next_state, record = reducer(
            state:copy(), {add, id, 1, alias="foobar"}
        )
        T:assert(next_state:get(component.value, id) == 2)
        T:assert(record:maybe_find("foobar"):has_value())
        T:assert(record:maybe_info_from_alias("foobar"):has_value())
    end)

    T("add_and_repeat", function(T)
        local next_state, record = reducer(
            state:copy(), {add_and_repeat, id, 1}
        )
        T:assert(next_state:get(component.value, id) == 3)
    end)

    T("recursive", function(T)
        local num, record = reducer(1, {factorial, 3, alias="root"})
        T:assert(num == 6)

        local maybe_children = record
            :maybe_find("root")
            :map(function(node) return record.tree:children(node) end)
            :map(function(children)
                return children:map(type_from_action)
            end)

        local expected_children_types = list(multiply, factorial)
        T:assert(maybe_children:value() == expected_children_types)
    end)
end)
