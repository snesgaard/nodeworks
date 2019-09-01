require "nodeworks"
local fsm = require "nodeworks.fsm"

COLOR = {
    ACTIVE = {0.3, 0.8, 0.3},
    PRESS = {0.3, 0.3, 0.8},
    SELECT = {0.8, 0.8, 0.3},
    INACTIVE = {0.5, 0.5, 0.5}
}

function textbox(graph, x, y, text, w, h, align)
    w = w or 60
    h = h or 60
    local textopt = {font=font(30), align=align}
    graph
        :branch("transform", nodes.transform, x, y)
        :branch("color", nodes.color, "blend", unpack(COLOR.ACTIVE))
            :leaf("box_bg", nodes.rectangle, "fill", 0, 0, w, h)
        :branch("line_color", nodes.color, "blend", 0.3, 0.3, 0.3)
        :branch("line", nodes.line, 5)
            :leaf("box_line", nodes.rectangle, "line", 0, 0, w, h)
            :leaf("text", nodes.text, text, w, h, textopt)
end

function love.load()
    root = graph()
    root
        :branch("transform", nodes.transform, 10, 100)

    for i = 0, 9 do
        local x, y = 80 * i, 0
        root:leaf("digit_" .. i, textbox, x, y, tostring(i))
    end

    operators = {{'add', '+'}, {'sub', '-'}, {'mul', '*'}, {'div', '/'}}
    for i, key in ipairs(operators) do
        local x, y = 80 * (i - 1), 80
        local name, text = unpack(key)
        root:leaf("op_" .. name, textbox, x, y, text)
    end

    root:leaf("cumul", textbox, 0, 160, "0", 300, 60, "right")
end

function love.draw()
    root:traverse()
end
