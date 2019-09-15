local color_nodes = {
    add = {}, sub = {}, dot = {}, darken = {}, set = {}
}

function color_nodes.add:begin(...)
    self.color = color.create(...)
end

function color_nodes.add:enter()
    colorstack:map(add, self.color)
end

function color_nodes.sub:begin(...)
    self.color = color.create(...)
end

function color_nodes.sub:enter()
    colorstack:map(sub, self.color)
end

function color_nodes.dot:begin(...)
    self.color = color.create(...)
end

function color_nodes.dot:enter()
    colorstack:map(dot, self.color)
end

function color_nodes.darken:begin(value)
    self.value = value
end

function color_nodes.darken:enter()
    colorstack:map(color.darken, self.value)
end

function color_nodes.set:begin(r, g, b, a)
    self.color = color.create(r, g, b, a)
end

function color_nodes.set:enter()
    local c = colorstack:peek()
    colorstack:set(c:set(unpack(self.color)))
end

for _, node in pairs(color_nodes) do
    function node.memory()
        colorstack:push()
    end

    function node.exit()
        colorstack:pop()
    end
end

return color_nodes
