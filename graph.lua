local node = {}
node.__index = node

function node.create()
    return setmetatable({_leaves={}}, node)
end

function node:branch(tag, constructor, ...)
    setmetatable(constructor, {__index = node})
    constructor.__index = constructor
    local n = node.create()
    setmetatable(n, constructor)
    constructor.begin(n, ...)
    local index = #self._leaves + 1
    self._leaves[n] = index
    self._leaves[#self._leaves + 1] = n
    self._leaves[tag] = n
    return n
end

function node:enter()
end

function node.memory()
end

function node.begin()
end

function node:exit()
end

function node:leaf(...)
    self:branch(...)
    return self
end

local function do_depth_first_list(node, list)
    list[#list + 1] = node
    for _, leaf in ipairs(node._leaves) do
        do_depth_first_list(leaf, list)
    end
    return list
end

function node:invoke(name, ...)
    local node_list = do_depth_first_list(self, {})

    for _, node in ipairs(node_list) do
        local f = node[name]
        if f then f(node, ...) end
    end
end

function node:find(path, ...)
    local parts = string.split(path, "/")
    local n = self
    for _, p in ipairs(parts) do
        local next = n._leaves[p]
        if not next then return end
        n = next
    end
    return n
end

function node:traverse(...)
    local memory = self:memory(...)
    self:enter(...)
    for _, node in ipairs(self._leaves) do
        node:traverse(...)
    end
    self:exit(memory, ...)
end

function node:adopt(name, graph)
    local index = #self._leaves + 1
    self._leaves[n] = index
    self._leaves[#self._leaves + 1] = n
end

return function()
    return node.create()
end
