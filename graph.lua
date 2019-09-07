local node = {}
node.__index = node

function node:enter() end

function node:memory() end

function node:exit() end

function node:begin() end

function node:forward(...) end

function node:inverse(...) end

function node:clear() end

function node:prechild() end
function node:postchild() end

local graph = {}
graph.__index = graph

function graph.create()
    local this = {
        _edges = {},
        _nodes = {},
        _root = nil,
        _last_node = "root"
    }
    return setmetatable(this, graph)
end

function graph:back(path)
    self._last_node = path or "root"
    return self
end

local function create_leaf(self, name, nodetype, ...)
    local t = type(nodetype)
    if t == "table" then
        self:node(name, nodetype, ...)
        self:edge(self._last_node, name)
        return name
    elseif t == "function" then
        -- Do subgraph stuff instead
        local _, root, tail = self:subgraph(name, nodetype, ...)
        self:edge(self._last_node, root)
        return tail
    else
        error(string.format("Unsupported node type <%s>", t))
    end
end

function graph:leaf(name, nodetype, ...)
    create_leaf(self, name, nodetype, ...)
    return self
end

function graph:branch(name, nodetype, ...)
    local tail_node = create_leaf(self, name, nodetype, ...)
    if not tail_node then
        local msg = string.format(
            "Branching without defining tail node. name:<%s> type:<%s>",
            name, type(nodetype)
        )
        error(msg)
    end
    self._last_node = tail_node
    return self
end

function graph:node(name, nodetype, ...)
    if type(nodetype) ~= "table" then
        error(string.format("Node was of invalid type <%s>", type(nodetype)))
    end
    setmetatable(nodetype, {__index=node})
    nodetype.__index = nodetype
    local this = setmetatable({}, node)
    setmetatable(this, nodetype)
    this:begin(...)
    self:_addnode(name, this)
    return self
end

function graph:_addnode(name, node)
    if self._nodes[name] then
        log.warn("Overwriting <%s>", name)
    else
        log.debug("adding %s", name)
    end
    self._nodes[name] = node
    return self
end

function graph:edge(from, to)
    if not self._edges[from] then
        self._edges[from] = list()
    end
    local l = self._edges[from]
    -- Check for duplicates
    if l:argfind(to) then
        return
    end
    l[#l + 1] = to
    return self
end

function graph:root(name)
    self._root = name
    return self
end

function graph:clear(path)
    path = path or "root"
    if not path then
        error("A path must either be supplied or root defined")
    end
    local n = self:find(path)
    if n then
        n:clear()
    end
    for _, c in ipairs(self._edges[path] or {}) do
        self:clear(c)
    end
end

function graph:traverse(path)
    path = path or "root"
    if not path then
        error("A path must either be supplied or root defined")
    end

    local n = self:find(path)
    local m
    if n then
        m = {n:memory()}
        n:enter()
    end
    for _, c in ipairs(self._edges[path] or {}) do
        n:prechild()
        self:traverse(c)
        n:postchild()
    end
    if n then
        n:exit(unpack(m))
    end
end

function graph:find(path)
    local n = self._nodes[path]
    if not n then
        --log.warn("Node %s not found", path)
    end
    return n
end

function graph:regexfind(pattern)
    local ret = dict()
    for path, node in pairs(self._nodes) do
        if string.match(path, pattern) then
            ret[path] = node
        end
    end
    return ret
end

function graph:subgraph(namespace, f, ...)
    local function get_sub(f, ...)
        if type(f) == "function" then
            local subgraph = graph.create()
            local tail_node = f(subgraph, ...)
            return subgraph, tail_node
        else
            return f
        end
    end
    local ns = namespace
    local subgraph, tail_node = get_sub(f, ...)
    for path, n in pairs(subgraph._nodes) do
        self:_addnode(string.join(ns, path), n)
    end
    for from, edges in pairs(subgraph._edges) do
        local from_path = string.join(ns, from)
        for _, e in pairs(edges) do
            self:edge(from_path, string.join(ns, e))
        end
    end
    if tail_node then
        return self, string.join(ns, "root"), string.join(ns, tail_node)
    else
        return self, string.join(ns, "root")
    end
end

return function()
    return graph.create()
end
