local function digit_key(i)
    return "digit_" .. i
end

local function op_key(i)
    return "op_" .. i
end

local function set_color(path, color)
    local node = root:find(string.join(path, "color"))
    if node then
        node.color = color
    end
end

local pick_digit = {}

function pick_digit:enter(data)
    for i = 0, max_digit do
        set_color(digit_key(i), COLOR.ACTIVE)
    end

    set_color(digit_key(data.digit), COLOR.PRESS)
end

function pick_digit:left(data)
    local next_digit = (data.digit - 1) % (data.max_digit + 1)
    set_color(digit_key(data.digit), COLOR.ACTIVE)
    set_color(digit_key(data.next_digit), COLOR.PRESS)
    data.digit = next_digit
end

function pick_digit:right(data)
    local next_digit = (data.digit + 1) % (data.max_digit + 1)
    set_color(digit_key(data.digit), COLOR.ACTIVE)
    set_color(digit_key(data.next_digit), COLOR.PRESS)
    data.digit = next_digit
end

local pick_operator = {}

function pick_operation:enter(data)
    data.operation = data.operation or 1
    for _, name in pairs(data.operators) do
        set_color(op_key(name), COLOR.ACTIVE)
    end

    set_color(op_key(data.operators[data.operation]), COLOR.PRESS)

    if data.digit == 0 then
        -- DISABLE division operator to prevent division by 0
        set_color(op_key('div'), COLOR.INACTIVE)
    end
end

function pick_operator.get_max_operators(data)
    local max = #data.operators
    return data.digit == 0 and max - 1 or max
end

function pick_operation:left(data)

end

function pick_operation:right(data)

end

function pick_operation:cancel()

end

return {
    init = "pick_digit",
    data = {
        value = 0,
        digit = nil,
        operation = nil,
        max_digit = 9,
        operators = {'add', 'sub', 'mul', 'div'}
    },
    states = {
        pick_digit=pick_digit, pick_operator=pick_operator, execute=execute
    },
    edges = {
        {name="cancel", from="pick_operator", to="pick_digit"},
        {name="confirm", from="pick_digit", to="pick_operator"},
        {name="confirm", from="pick_operator", to="execute"},
        {name="done", from="execute", to="pick_digit"}
    },
    methods = {},
}
